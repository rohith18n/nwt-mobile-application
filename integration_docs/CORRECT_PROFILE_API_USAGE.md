# ✅ CORRECT Profile API Usage (Based on Backend Documentation)

## The Problem

Your current code sends **wrong field names** that don't match the backend API specification in `profile.md`.

### ❌ What You're Sending (WRONG)
```dart
{
  "extended_profile": {
    "first_name": "DARSHAN",           // Wrong!
    "last_name": "KOTIAN",             // Wrong!
    "pan": "JVHPK6199D",               // Wrong location!
    "dob": "2002-03-15",               // Wrong location!
    "phone": "+919136247925",          // Wrong location & format!
    "gender": "M",                     // Wrong key!
    "tax_status": "01",                // Wrong key!
    "politically_exposed_person": "N"  // Wrong key!
  }
}
```

## ✅ The Solution

Use the new `ProfileService.buildExtendedProfile()` helper method:

```dart
import 'package:nwt_app/services/auth/profile_service.dart';

final profileService = ProfileService();

// Step 1: Build extended_profile with CORRECT field names
final extendedProfile = profileService.buildExtendedProfile(
  // Personal Information
  firstName: 'DARSHAN',
  middleName: '',
  lastName: 'KOTIAN',
  email: 'darshankotiann@gmail.com',
  gender: 'M',
  pep: 'N',
  
  // Address (REQUIRED for profile completion)
  addressLine1: 'Shiv shankar nagar deonar',
  addressLine2: 'Farm road',
  city: 'Mumbai Suburban',
  state: 'Maharashtra',
  pincode: '400088',
  country: 'IND',
  
  // Signature (REQUIRED for submit_profile: true)
  // primarySignature: 'data:image/png;base64,...',
);

// Step 2: Call API with top-level fields
final response = await profileService.updateProfileDetails(
  extendedProfile: extendedProfile,
  
  // Top-level fields (NOT in extended_profile)
  investorResidency: 'Resident',      // Not 'tax_status'!
  phoneNumber: '9136247925',          // No + prefix!
  dob: '2002-03-15',                  // YYYY-MM-DD
  panNumber: 'JVHPK6199D',
  name: 'Darshan Kotian',
  
  submitProfile: false, // Set to true only when signature is available
);
```

## What Gets Sent (CORRECT)

```json
{
  "investor_residency": "Resident",
  "phone_number": "9136247925",
  "dob": "2002-03-15",
  "pan_number": "JVHPK6199D",
  "name": "Darshan Kotian",
  "extended_profile": {
    "primary_first_name": "DARSHAN",
    "primary_last_name": "KOTIAN",
    "primary_email": "darshankotiann@gmail.com",
    "primary_gender": "M",
    "primary_pep": "N",
    "address_line_1": "Shiv shankar nagar deonar",
    "address_line_2": "Farm road",
    "city": "Mumbai Suburban",
    "state": "Maharashtra",
    "pincode": "400088",
    "country": "IND"
  },
  "submit_profile": false
}
```

## Complete Example for BSE Personal Information Screen

```dart
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/types/auth/profile_details.dart';
import 'package:nwt_app/utils/logger.dart';

class _HolderManagementState extends State<HolderManagement> {
  final ProfileService _profileService = ProfileService();
  
  Future<void> _savePersonalInformation() async {
    AppLogger.info(
      'Starting personal information save',
      tag: 'BSE_Personal_Information',
    );
    
    setState(() => _isLoading = true);
    
    try {
      // Get existing profile to pull address data
      final existingProfile = await _profileService.getProfileDetails();
      final uccAddress = existingProfile?.data?.uccProfile?['address'];
      
      // Build extended_profile with correct field names
      final extendedProfile = _profileService.buildExtendedProfile(
        // Personal Information from form
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender, // 'M', 'F', 'O'
        pep: _selectedPep, // 'N', 'Y', 'R'
        
        // Address from existing ucc_profile (if available)
        addressLine1: uccAddress?['address1'] ?? '',
        addressLine2: uccAddress?['address2'] ?? '',
        city: uccAddress?['city'] ?? '',
        state: uccAddress?['state'] ?? '',
        pincode: uccAddress?['pincode'] ?? '',
        country: uccAddress?['country'] ?? 'IND',
        
        // Signature - will be added in signature screen
        // primarySignature: signatureBase64,
      );
      
      AppLogger.info(
        'Extended profile keys: ${extendedProfile.keys.toList()}',
        tag: 'BSE_Personal_Information',
      );
      
      // Call API with top-level fields
      final response = await _profileService.updateProfileDetails(
        extendedProfile: extendedProfile,
        investorResidency: 'Resident', // or from _selectedTaxStatus
        phoneNumber: _phoneController.text.trim(), // Just digits, no +
        dob: _dobController.text.trim(), // YYYY-MM-DD
        panNumber: _panController.text.trim().toUpperCase(),
        name: '${_firstNameController.text} ${_lastNameController.text}',
        submitProfile: false, // Don't submit until signature is added
      );
      
      if (response != null && response.success) {
        AppLogger.info(
          'Profile updated successfully. Status: ${response.onboardingStatus}',
          tag: 'BSE_Personal_Information',
        );
        
        AppLogger.info(
          'Profile complete: ${response.data?.profileComplete}, Issues: ${response.data?.profileIssues}',
          tag: 'BSE_Personal_Information',
        );
        
        // Move to next screen
        widget.onNext?.call();
      } else {
        AppLogger.error(
          'Profile update failed: ${response?.message}',
          tag: 'BSE_Personal_Information',
        );
        
        // Show validation errors
        final issues = response?.data?.profileIssues ?? [];
        if (issues.isNotEmpty) {
          _showValidationErrors(issues);
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error saving personal information',
        error: e,
        tag: 'BSE_Personal_Information',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showValidationErrors(List<String> issues) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Missing fields:\n${issues.join('\n')}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
```

## Field Name Mapping Reference

| Your Form Field | Top-Level API Field | Extended Profile Field | Notes |
|----------------|---------------------|------------------------|-------|
| First Name | - | `primary_first_name` | Required |
| Middle Name | - | `primary_middle_name` | Optional |
| Last Name | - | `primary_last_name` | Required |
| Email | - | `primary_email` | Required |
| Gender | - | `primary_gender` | Optional (M/F/O) |
| PEP | - | `primary_pep` | Optional (N/Y/R) |
| Phone | `phone_number` | - | Required, no + prefix |
| DOB | `dob` | - | Required (YYYY-MM-DD) |
| PAN | `pan_number` | - | Required |
| Tax Status | `investor_residency` | - | Required (Resident/NRI-NRE/NRI-NRO) |
| Address Line 1 | - | `address_line_1` | Required |
| City | - | `city` | Required |
| State | - | `state` | Required |
| Pincode | - | `pincode` | Required |
| Signature | - | `primary_signature` | Required for submit |

## Required Fields for Profile Completion

### For Resident Investors:
1. ✅ `phone_number`, `dob`, `pan_number` (top-level)
2. ✅ `investor_residency` = "Resident" (top-level)
3. ✅ `primary_first_name`, `primary_last_name`, `primary_email` (extended_profile)
4. ✅ `address_line_1`, `city`, `state`, `pincode` (extended_profile)
5. ✅ `primary_signature` (extended_profile) - PNG data URL

### For NRI Investors (NRI-NRE / NRI-NRO):
All of the above, PLUS:
6. ✅ `primary_tax_id` (foreign TIN) (extended_profile)
7. ✅ `country` must NOT be "IND" (extended_profile)

## When to Use submit_profile

```dart
// Save partial data (allows missing fields)
submitProfile: false

// Validate and advance onboarding (requires ALL fields)
submitProfile: true
```

## Common Mistakes to Avoid

1. ❌ Using `first_name` instead of `primary_first_name`
2. ❌ Putting `pan`, `dob`, `phone` in `extended_profile`
3. ❌ Using `tax_status` instead of `investor_residency`
4. ❌ Adding `+` prefix to phone number
5. ❌ Using `politically_exposed_person` instead of `primary_pep`
6. ❌ Calling with `submit_profile: true` without signature

## Success!

After fixing the field names, your API call will succeed and you'll get:

```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "profile_complete": false,
    "identity_verified": true,
    "profile_issues": ["Digital signature (PNG data URL, required for agreements)"]
  }
}
```

Then add the signature and call again with `submit_profile: true` to advance to `ucc` status! 🎉
