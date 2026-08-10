# Profile API Error Fix

## Error Analysis

Your current request is **WRONG** because it's using incorrect field names:

```json
{
  "extended_profile": {
    "first_name": "DARSHAN",        // ❌ Should be "primary_first_name"
    "last_name": "KOTIAN",          // ❌ Should be "primary_last_name"
    "pan": "JVHPK6199D",            // ❌ Should be top-level "pan_number"
    "dob": "2002-03-15",            // ❌ Should be top-level "dob"
    "phone": "+919136247925",       // ❌ Should be top-level "phone_number" (no +)
    "email": "darshankotiann@gmail.com",
    "gender": "M",                  // ❌ Should be "primary_gender"
    "tax_status": "01",             // ❌ Should be top-level "investor_residency"
    "politically_exposed_person": "N", // ❌ Should be "primary_pep"
    "communication_mode": "E",
    "holder_rank": 1
  },
  "submit_profile": true
}
```

## API Response Error

```
"profile_issues": [
  "First name",                    // Missing primary_first_name
  "Last name",                     // Missing primary_last_name
  "Correspondence address line 1", // Missing address_line_1
  "City",                          // Missing city
  "State",                         // Missing state
  "Pincode",                       // Missing pincode
  "Digital signature (PNG data URL, required for agreements)" // Missing primary_signature
]
```

## Correct Request Format

```json
{
  "phone_number": "9136247925",           // Top-level, no + prefix
  "dob": "2002-03-15",                    // Top-level
  "pan_number": "JVHPK6199D",             // Top-level
  "investor_residency": "Resident",       // Top-level (not tax_status)
  "name": "Darshan Kotian",               // Top-level
  "extended_profile": {
    "primary_first_name": "DARSHAN",      // ✅ Correct
    "primary_middle_name": "",            // ✅ Optional
    "primary_last_name": "KOTIAN",        // ✅ Correct
    "primary_email": "darshankotiann@gmail.com", // ✅ Correct
    "primary_gender": "M",                // ✅ Correct
    "primary_pep": "N",                   // ✅ Correct
    
    // Address (REQUIRED for profile completion)
    "address_line_1": "Shiv shankar nagar deonar", // ✅ From your existing data
    "address_line_2": "Farm road",                 // Optional
    "city": "Mumbai Suburban",                     // ✅ Required
    "state": "Maharashtra",                        // ✅ Required
    "pincode": "400088",                           // ✅ Required
    "country": "IND",                              // For Resident
    
    // Signature (REQUIRED for profile completion)
    "primary_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..." // ✅ Required
  },
  "submit_profile": true
}
```

## Where to Get Missing Data

Based on your error, you already have this data in `ucc_profile`:

```json
"ucc_profile": {
  "address": {
    "address1": "Shiv shankar nagar deonar",  // → address_line_1
    "address2": "Farm road",                   // → address_line_2
    "city": "Mumbai Suburban",                 // → city
    "state": "Maharashtra",                    // → state
    "pincode": "400088",                       // → pincode
    "country": "IND"                           // → country
  }
}
```

## Quick Fix Code

```dart
// In HolderManagement or wherever you're calling the API

Future<void> _savePersonalInformation() async {
  AppLogger.info('Starting personal information save', tag: 'BSE_Personal_Information');
  
  // Get existing profile data to fill address
  final profileData = await ProfileService().getProfileDetails();
  final existingAddress = profileData?.data?.uccProfile?['address'];
  
  final extendedProfile = {
    // Personal info
    'primary_first_name': _firstNameController.text.trim(),
    'primary_middle_name': _middleNameController.text.trim(),
    'primary_last_name': _lastNameController.text.trim(),
    'primary_email': _emailController.text.trim(),
    'primary_gender': _selectedGender,
    'primary_pep': _selectedPep,
    
    // Address from existing data or address screen
    'address_line_1': existingAddress?['address1'] ?? '',
    'address_line_2': existingAddress?['address2'] ?? '',
    'city': existingAddress?['city'] ?? '',
    'state': existingAddress?['state'] ?? '',
    'pincode': existingAddress?['pincode'] ?? '',
    'country': existingAddress?['country'] ?? 'IND',
    
    // Signature - TODO: Get from signature screen
    // For now, you might need to skip submit_profile until signature is added
    // 'primary_signature': signatureBase64,
  };
  
  final response = await ProfileService().updateProfileDetails(
    extendedProfile: extendedProfile,
    investorResidency: 'Resident', // or _selectedTaxStatus.code
    phoneNumber: _phoneController.text.trim(), // No + prefix!
    dob: _dobController.text.trim(),
    panNumber: _panController.text.trim().toUpperCase(),
    name: '${_firstNameController.text} ${_lastNameController.text}',
    submitProfile: false, // Set to true only when signature is available
  );
  
  AppLogger.info(
    'Profile update response: success=${response?.success}, status=${response?.onboardingStatus}',
    tag: 'BSE_Personal_Information',
  );
}
```

## Key Takeaways

1. **Field Names Matter**: Use `primary_first_name`, not `first_name`
2. **Top-Level vs Extended**: `phone_number`, `dob`, `pan_number` go at top level
3. **Phone Format**: No `+` prefix, just digits: `"9136247925"`
4. **Address Required**: Even for Personal Info screen, address fields are required
5. **Signature Required**: `primary_signature` is required for `submit_profile: true`
6. **Use Existing Data**: Pull address from `ucc_profile` if already saved

## Recommendation

For the **Personal Information screen**, save with `submit_profile: false` since you don't have address and signature yet:

```dart
submitProfile: false, // Don't validate yet, just save personal info
```

Then on **Address screen** and **Signature screen**, save those fields. Finally, when all data is collected, call with `submit_profile: true`.
