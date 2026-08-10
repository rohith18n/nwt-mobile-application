# Complete Onboarding Flow Integration Guide

Based on `profile.md` and `ucc.md` backend documentation.

## Onboarding Status Flow

```
pan → bank → profile → ucc → order
```

## Complete Journey Overview

### Phase 1: Identity Verification (Status: `pan`)
1. **PAN Verification** → Moves to `bank`

### Phase 2: Bank Details (Status: `bank`)
2. **Bank Account** → Moves to `profile`

### Phase 3: Profile Completion (Status: `profile`)
3. **Personal Information** (save with `submit_profile: false`)
4. **Address Details** (save with `submit_profile: false`)
5. **Personal Details (FATCA)** (save with `submit_profile: false`)
6. **Signature** (save with `submit_profile: true`) → Moves to `ucc`

### Phase 4: UCC Account Creation (Status: `ucc`)
7. **Nominee Details** → Create UCC account
8. **OTP Verification** → Moves to `order`

### Phase 5: Complete (Status: `order`)
9. **Dashboard** - User can start investing

---

## Detailed API Integration

### 1. PAN Verification (Status: `pan` → `bank`)

**API:** `POST /api/v1/profile/pan_verify/`

```dart
import 'package:nwt_app/services/auth/profile_service.dart';

final response = await ProfileService().verifyPan(
  name: 'Darshan Shankar Kotian',
  panNumber: 'JVHPK6199D',
  dob: '2002-03-15', // YYYY-MM-DD
);

// Success: onboarding_status moves to "bank"
```

**Response:**
```json
{
  "success": true,
  "message": "Identity verified successfully!",
  "data": {
    "onboarding_status": "bank",
    "kyc_status": "VALID",
    "is_name_matched": true,
    "is_dob_matched": true
  }
}
```

---

### 2. Bank Details (Status: `bank` → `profile`)

**API:** `POST /api/v1/profile/bank_details/`

```dart
final response = await ProfileService().updateBankDetails(
  accountNumber: '3748798017',
  ifscCode: 'KKBK0000960',
  bankType: 'SB', // SB, CB, NE, NO
  upiId: 'darshan@paytm', // Optional
  bankName: 'KOTAK MAHINDRA BANK', // Optional
);

// Success: onboarding_status moves to "profile"
```

**Response:**
```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "account_number": "3748798017",
    "ifsc_code": "KKBK0000960",
    "bank_type": "SB",
    "onboarding_status": "profile"
  }
}
```

---

### 3. Personal Information (Status: `profile`)

**API:** `POST /api/v1/profile/details_update/`

**Save WITHOUT submit** (allows partial data):

```dart
final profileService = ProfileService();

// Get existing data to preserve address
final existingProfile = await profileService.getProfileDetails();
final uccAddress = existingProfile?.data?.uccProfile?['address'];

// Build extended_profile with correct field names
final extendedProfile = profileService.buildExtendedProfile(
  // Personal Information
  firstName: 'DARSHAN',
  middleName: '',
  lastName: 'KOTIAN',
  email: 'darshankotiann@gmail.com',
  gender: 'M', // M, F, O
  pep: 'N', // N, Y, R
  
  // Address (use existing if available)
  addressLine1: uccAddress?['address1'] ?? '',
  addressLine2: uccAddress?['address2'] ?? '',
  city: uccAddress?['city'] ?? '',
  state: uccAddress?['state'] ?? '',
  pincode: uccAddress?['pincode'] ?? '',
  country: 'IND',
);

final response = await profileService.updateProfileDetails(
  extendedProfile: extendedProfile,
  investorResidency: 'Resident', // Resident, NRI-NRE, NRI-NRO
  phoneNumber: '9136247925', // No + prefix!
  dob: '2002-03-15',
  panNumber: 'JVHPK6199D',
  name: 'Darshan Kotian',
  submitProfile: false, // Don't validate yet
);
```

**Response:**
```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "profile_complete": false,
    "profile_issues": ["Digital signature (PNG data URL, required for agreements)"]
  }
}
```

---

### 4. Address Details (Status: `profile`)

**API:** `POST /api/v1/profile/details_update/`

```dart
final extendedProfile = profileService.buildExtendedProfile(
  addressLine1: 'Shiv shankar nagar deonar',
  addressLine2: 'Farm road',
  city: 'Mumbai Suburban',
  state: 'Maharashtra',
  pincode: '400088',
  country: 'IND',
);

final response = await profileService.updateProfileDetails(
  extendedProfile: extendedProfile,
  submitProfile: false, // Still not submitting
);
```

---

### 5. Personal Details / FATCA (Status: `profile`)

**API:** `POST /api/v1/profile/details_update/`

```dart
final extendedProfile = profileService.buildExtendedProfile(
  occupation: '01', // 01-08
  incomeSlab: '31', // 31-35
  placeOfBirth: 'Mumbai',
  // For NRI: add primaryTaxId
);

final response = await profileService.updateProfileDetails(
  extendedProfile: extendedProfile,
  submitProfile: false,
);
```

---

### 6. Signature (Status: `profile` → `ucc`)

**API:** `POST /api/v1/profile/details_update/`

**This is the FINAL step** - Submit with signature:

```dart
final extendedProfile = profileService.buildExtendedProfile(
  primarySignature: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...',
);

final response = await profileService.updateProfileDetails(
  extendedProfile: extendedProfile,
  submitProfile: true, // ✅ NOW submit and validate
);

// Success: onboarding_status moves to "ucc"
```

**Response:**
```json
{
  "success": true,
  "onboarding_status": "ucc",
  "data": {
    "status": "ok",
    "message": "Your profile is verified. You can continue to the next step.",
    "profile_complete": true,
    "identity_verified": true,
    "profile_issues": []
  }
}
```

---

### 7. Nominee Details & UCC Creation (Status: `ucc`)

**API:** `POST /api/v1/account/create/` OR `POST /api/v1/account/create_without_nominee/`

#### Option A: With Nominees

```dart
final response = await NetworkAPIHelper().post(
  ApiURLs.ACCOUNT_CREATE,
  {
    "accounts": "si", // or "as", "both", ["SI", "AS"]
    "nomination": {
      "choice": "provide",
      "nominee_soa": true,
      "nominees": [
        {
          "first_name": "John",
          "last_name": "Doe",
          "middle_name": "",
          "dob": "1995-05-15",
          "percent": 100,
          "relation": "Brother",
          "is_minor": false,
          "pan": "ABCDE1234F",
          "mobile": "9876543210",
          "email": "john@example.com",
          "address_line_1": "123 Street",
          "city": "Mumbai",
          "state": "MH",
          "pincode": "400001",
        }
      ]
    }
  },
);
```

**Response:**
```json
{
  "success": true,
  "message": "Check your email for a verification code, then call account/otp_verify with purpose bse.",
  "data": {
    "accounts": [
      { "holding_nature": "SI", "client_code": "PIVOT000071" }
    ]
  }
}
```

#### Option B: Without Nominees

```dart
final response = await NetworkAPIHelper().post(
  ApiURLs.ACCOUNT_CREATE_WITHOUT_NOMINEE,
  {
    "accounts": "si",
  },
);
```

**Response:**
```json
{
  "success": true,
  "message": "Check your email for the nominee opt-out code, then call account/otp_verify with purpose nominee_opt_out.",
  "data": {
    "accounts": [
      { "holding_nature": "SI", "client_code": "PIVOT000071" }
    ]
  }
}
```

---

### 8. OTP Verification (Status: `ucc` → `order`)

**API:** `POST /api/v1/account/otp_verify/`

#### With Nominees (Direct BSE Verification)

```dart
final response = await NetworkAPIHelper().post(
  ApiURLs.ACCOUNT_OTP_VERIFY,
  {
    "client_code": "PIVOT000071",
    "otp": "123456",
    "purpose": "bse", // or "bse_submit", "exchange"
  },
);
```

#### Without Nominees (Two-Step Process)

**Step 1: Verify Opt-Out OTP**
```dart
final response = await NetworkAPIHelper().post(
  ApiURLs.ACCOUNT_OTP_VERIFY,
  {
    "client_code": "PIVOT000071",
    "otp": "123456",
    "purpose": "nominee_opt_out", // or "opt_out"
  },
);
```

**Step 2: Verify BSE OTP (from second email)**
```dart
final response = await NetworkAPIHelper().post(
  ApiURLs.ACCOUNT_OTP_VERIFY,
  {
    "client_code": "PIVOT000071",
    "otp": "789012",
    "purpose": "bse",
  },
);
```

**Success Response:**
```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "status": "ok"
  }
}
```

**After this, onboarding_status moves to `order`** ✅

---

## API URLs to Add

Add these to `lib/constants/api.dart`:

```dart
// ── Account V1 (ucc.md) ───────────────────────────────────────────────────
static String get ACCOUNT_CREATE                => '$_v1BaseUrl/account/create/';
static String get ACCOUNT_CREATE_WITHOUT_NOMINEE => '$_v1BaseUrl/account/create_without_nominee/';
static String get ACCOUNT_OTP_VERIFY            => '$_v1BaseUrl/account/otp_verify/';
```

---

## Complete Flow Summary

```
1. PAN Verification (pan → bank)
   └─> POST /profile/pan_verify/

2. Bank Details (bank → profile)
   └─> POST /profile/bank_details/

3. Personal Information (profile, save)
   └─> POST /profile/details_update/ (submit_profile: false)

4. Address Details (profile, save)
   └─> POST /profile/details_update/ (submit_profile: false)

5. FATCA Details (profile, save)
   └─> POST /profile/details_update/ (submit_profile: false)

6. Signature (profile → ucc)
   └─> POST /profile/details_update/ (submit_profile: true)

7. Nominee Details (ucc)
   ├─> POST /account/create/ (with nominees)
   └─> POST /account/create_without_nominee/ (skip nominees)

8. OTP Verification (ucc → order)
   ├─> POST /account/otp_verify/ (purpose: "bse")
   └─> POST /account/otp_verify/ (purpose: "nominee_opt_out" then "bse")

9. Dashboard (order) ✅
```

---

## Key Points

1. **Profile can be saved incrementally** with `submit_profile: false`
2. **Only submit when signature is added** with `submit_profile: true`
3. **UCC creation requires complete profile** (all fields + signature)
4. **Phone number format**: No `+` prefix, just digits
5. **Field names**: Use `primary_first_name`, not `first_name`
6. **Top-level vs extended_profile**: `phone_number`, `dob`, `pan_number`, `investor_residency` are top-level
7. **Nominee flow**: Two paths - with nominees (1 OTP) or without (2 OTPs)

---

## Error Handling

### Profile Incomplete (400)
```json
{
  "success": false,
  "message": "Fill all required profile fields.",
  "data": {
    "profile_issues": ["First name", "Signature"],
    "profile_complete": false
  }
}
```

### UCC Creation Failed (400)
```json
{
  "success": false,
  "message": "Incomplete profile or missing joint holder"
}
```

### Invalid OTP (400/404)
```json
{
  "success": false,
  "message": "Invalid OTP or client code"
}
```

---

## Testing Checklist

- [ ] PAN verification with valid PAN
- [ ] Bank details save
- [ ] Personal info save (without submit)
- [ ] Address save (without submit)
- [ ] Signature save (with submit) → moves to `ucc`
- [ ] UCC creation with nominees
- [ ] UCC creation without nominees
- [ ] OTP verification (with nominees)
- [ ] OTP verification (without nominees - 2 step)
- [ ] Final status is `order`
- [ ] User can access dashboard
