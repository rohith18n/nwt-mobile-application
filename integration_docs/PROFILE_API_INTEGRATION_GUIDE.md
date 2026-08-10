# Profile Details Update API Integration Guide

## API Endpoint
`POST /api/v1/profile/details_update/`

## Already Configured

### 1. API URL (✅ Done)
Location: `lib/constants/api.dart:79`
```dart
static String get PROFILE_DETAILS_UPDATE => '$_v1BaseUrl/profile/details_update/';
```

### 2. Service Method (✅ Enhanced)
Location: `lib/services/auth/profile_service.dart:95-139`

The `ProfileService.updateProfileDetails()` method now supports:

```dart
Future<ProfileDetailsResponse?> updateProfileDetails({
  Map<String, dynamic>? extendedProfile,  // Nested profile fields
  String? investorResidency,              // 'Resident', 'NRI-NRE', 'NRI-NRO'
  String? phoneNumber,                    // 10+ digits
  String? dob,                            // 'YYYY-MM-DD'
  String? panNumber,                      // 10 chars
  String? name,                           // Display name
  bool submitProfile = false,             // Advance onboarding if true
})
```

### 3. Response Types (✅ Done)
Location: `lib/types/auth/profile_details.dart`

- `ProfileDetailsResponse` - Main response wrapper
- `ProfileDetailsData` - User profile data
- `ProfileRequirements` - Validation requirements
- `ProfileSection` - Required/optional fields by section

## Integration in BSE Journey (Personal Information Screen)

### Current Screen: `start_journey.dart` - Case 1 (Personal Information)

The screen uses `HolderManagement` widget which already has `ProfileService` imported.

### Implementation Example

```dart
// In HolderManagement widget (_holder_management.dart)

import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/types/auth/profile_details.dart';

class _HolderManagementState extends State<HolderManagement> {
  final ProfileService _profileService = ProfileService();
  
  Future<void> _savePersonalInformation() async {
    AppLogger.info(
      'Starting personal information save',
      tag: 'BSE_Personal_Information',
    );
    
    setState(() => _isLoading = true);
    
    try {
      // Build extended_profile object
      // IMPORTANT: Use correct API field names from profile.md
      final extendedProfile = {
        // Personal Information (required)
        'primary_first_name': _firstNameController.text.trim(),
        'primary_last_name': _lastNameController.text.trim(),
        'primary_email': _emailController.text.trim(),
        
        // Personal Information (optional)
        'primary_middle_name': _middleNameController.text.trim(),
        'primary_gender': _selectedGender, // 'M', 'F', 'O'
        'primary_pep': _selectedPep, // 'N', 'Y', 'R'
        
        // Address Information (required for Resident)
        // NOTE: These should come from Address Management screen
        // but are required for profile completion
        'address_line_1': '123 Main Street', // TODO: Get from address screen
        'city': 'Mumbai',                     // TODO: Get from address screen
        'state': 'MH',                        // TODO: Get from address screen
        'pincode': '400001',                  // TODO: Get from address screen
        'country': 'IND',                     // For Resident investors
        
        // Digital Signature (required)
        // NOTE: This should come from Signature Management screen
        'primary_signature': 'data:image/png;base64,...', // TODO: Get from signature screen
      };
      
      AppLogger.info(
        'Extended profile data: ${extendedProfile.keys.toList()}',
        tag: 'BSE_Personal_Information',
      );
      
      AppLogger.info(
        'Investor residency: ${_selectedTaxStatus.code}, PAN: ${_panController.text.trim().toUpperCase()}, DOB: ${_dobController.text.trim()}',
        tag: 'BSE_Personal_Information',
      );
      
      // Call the API
      // NOTE: phone_number, dob, pan_number are TOP-LEVEL fields, not in extended_profile
      final response = await _profileService.updateProfileDetails(
        extendedProfile: extendedProfile,
        investorResidency: _selectedTaxStatus.code, // 'Resident', 'NRI-NRE', 'NRI-NRO'
        phoneNumber: _phoneController.text.trim(), // Just digits, no country code prefix
        dob: _dobController.text.trim(), // 'YYYY-MM-DD'
        panNumber: _panController.text.trim().toUpperCase(),
        name: '${_firstNameController.text} ${_lastNameController.text}',
        submitProfile: false, // Set to true when moving to next step
      );
      
      if (response != null && response.success) {
        AppLogger.info(
          'Profile updated successfully. Onboarding status: ${response.onboardingStatus}',
          tag: 'BSE_Personal_Information',
        );
        
        AppLogger.info(
          'Profile complete: ${response.data?.profileComplete}, Identity verified: ${response.data?.identityVerified}',
          tag: 'BSE_Personal_Information',
        );
        
        // Check if profile is complete
        if (response.data?.profileComplete == true) {
          AppLogger.info(
            'Profile is complete, proceeding to next step',
            tag: 'BSE_Personal_Information',
          );
          // Profile is complete, can proceed
          widget.onNext?.call();
        } else {
          // Show validation errors
          final issues = response.data?.profileIssues ?? [];
          if (issues.isNotEmpty) {
            AppLogger.info(
              'Profile validation issues: ${issues.join(", ")}',
              tag: 'BSE_Personal_Information',
            );
            _showValidationErrors(issues);
          }
        }
      } else {
        // Handle error
        AppLogger.error(
          'Failed to update profile: ${response?.message}',
          tag: 'BSE_Personal_Information',
        );
        _showError(response?.message ?? 'Failed to update profile');
      }
    } catch (e) {
      AppLogger.error(
        'Error saving personal information',
        error: e,
        tag: 'BSE_Personal_Information',
      );
      _showError('An error occurred while saving');
    } finally {
      setState(() => _isLoading = false);
      AppLogger.info(
        'Personal information save completed',
        tag: 'BSE_Personal_Information',
      );
    }
  }
  
  void _showValidationErrors(List<String> issues) {
    // Display validation errors to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(issues.join('\n')),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## ⚠️ CRITICAL: Common Mistakes to Avoid

### 1. **Wrong Field Names in extended_profile**

❌ **WRONG:**
```json
{
  "extended_profile": {
    "first_name": "DARSHAN",     // Wrong!
    "last_name": "KOTIAN",       // Wrong!
    "pan": "JVHPK6199D",         // Wrong!
    "dob": "2002-03-15",         // Wrong!
    "phone": "+919136247925",    // Wrong!
    "email": "darshankotiann@gmail.com"
  }
}
```

✅ **CORRECT:**
```json
{
  "phone_number": "9136247925",           // Top-level (no + prefix)
  "dob": "2002-03-15",                    // Top-level
  "pan_number": "JVHPK6199D",             // Top-level
  "investor_residency": "Resident",       // Top-level
  "name": "Darshan Kotian",               // Top-level
  "extended_profile": {
    "primary_first_name": "DARSHAN",      // Correct!
    "primary_last_name": "KOTIAN",        // Correct!
    "primary_email": "darshankotiann@gmail.com",
    "primary_gender": "M",
    "address_line_1": "123 Main St",      // Required
    "city": "Mumbai",                     // Required
    "state": "MH",                        // Required
    "pincode": "400001",                  // Required
    "primary_signature": "data:image/png;base64,..." // Required
  }
}
```

### 2. **Phone Number Format**

❌ **WRONG:** `"+919136247925"` (with country code prefix)  
✅ **CORRECT:** `"9136247925"` (just digits)

### 3. **Missing Required Fields**

The API requires these fields for profile completion:
- ✅ `primary_first_name` and `primary_last_name` in `extended_profile`
- ✅ `address_line_1`, `city`, `state`, `pincode` in `extended_profile`
- ✅ `primary_signature` (PNG data URL) in `extended_profile`
- ✅ `phone_number`, `dob`, `pan_number` as **top-level** fields

### 4. **When to Use submit_profile**

- `submit_profile: false` - Save data without validation (allows partial saves)
- `submit_profile: true` - Validate and advance onboarding (requires all fields)

## Field Mapping for Personal Information Screen

Based on the screenshot and API documentation:

| UI Field | API Field (extended_profile) | Required | Notes |
|----------|------------------------------|----------|-------|
| First Name | `primary_first_name` | ✅ | Non-empty |
| Middle Name | `primary_middle_name` | ❌ | Optional |
| Last Name | `primary_last_name` | ✅ | Non-empty |
| PAN Number | Top-level `pan_number` | ✅ | 10 chars, unique |
| Date of Birth | Top-level `dob` | ✅ | Format: YYYY-MM-DD |
| Email | `primary_email` | ✅ | Valid email |
| Phone | Top-level `phone_number` | ✅ | 10+ digits |
| Gender | `primary_gender` | ❌ | 'M', 'F', 'O' |
| Tax Status | Top-level `investor_residency` | ✅ | 'Resident', 'NRI-NRE', 'NRI-NRO' |
| PEP Status | `primary_pep` | ❌ | 'N', 'Y', 'R' |

## Additional Fields for NRI Users

If `investor_residency` is 'NRI-NRE' or 'NRI-NRO', also include:

```dart
final extendedProfile = {
  // ... basic fields ...
  'primary_tax_id': 'AB123456C', // Foreign TIN - REQUIRED for NRI
  'country': 'USA', // Must NOT be 'IND' - REQUIRED
  'address_line_1': '100 Main St', // REQUIRED
  'city': 'New York', // REQUIRED
  'state': 'NY', // REQUIRED
  'pincode': '10001', // REQUIRED
  
  // Optional Indian address
  'ind_address_line_1': 'Optional Indian address',
  'ind_city': 'Mumbai',
  'ind_state': 'MH',
  'ind_pincode': '400001',
};
```

## Response Handling

### Success Response (200)

```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "status": "ok",
    "user": {
      "id": "...",
      "name": "...",
      "profile_complete": true,
      "identity_verified": true,
      "profile_issues": [],
      "profile_requirements": { ... }
    }
  }
}
```

### Submit Profile Success (moves to 'ucc')

```json
{
  "success": true,
  "onboarding_status": "ucc",
  "data": {
    "status": "ok",
    "message": "Your profile is verified. You can continue to the next step.",
    "user": { ... }
  }
}
```

### Validation Error (400)

```json
{
  "success": false,
  "message": "PAN verification must be complete with a matching name...",
  "data": {
    "profile_issues": [
      "PAN verification required",
      "Email is required"
    ],
    "identity_verified": false,
    "profile_complete": false
  }
}
```

## Best Practices

1. **Save without submit first**: Call with `submitProfile: false` to save data
2. **Validate before submit**: Check `profile_complete` and `profile_issues`
3. **Submit when ready**: Call with `submitProfile: true` to advance onboarding
4. **Handle errors gracefully**: Show specific validation errors to user
5. **Log for debugging**: Use AppLogger to track API calls and responses

## Testing Checklist

- [ ] Save personal information without submit
- [ ] Verify data is saved correctly
- [ ] Check validation errors are displayed
- [ ] Test with Resident investor
- [ ] Test with NRI-NRE investor
- [ ] Test with NRI-NRO investor
- [ ] Submit profile when complete
- [ ] Verify onboarding status advances to 'ucc'
- [ ] Test error handling for invalid data
- [ ] Test network error scenarios

## Next Steps

1. Update `HolderManagement` widget to call `_profileService.updateProfileDetails()`
2. Map form fields to API parameters
3. Handle response and validation errors
4. Test with different investor types
5. Integrate with BSE journey navigation flow
