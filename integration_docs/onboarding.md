# Onboarding API — Frontend Developer Guide

Base URL prefix: `/api/v2/` (unless noted as `/api/v1/`)  
All `/api/v2/` endpoints require `Authorization: Bearer <access_token>`.  
All responses are JSON. `"success": true` = action succeeded. `"success": false` = failed — read `message`.

---

## Full Flow at a Glance

```
Sign In (phone or email + OTP)
        │
        ▼
GET /api/v1/auth/status/   ──► route to correct onboarding step
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│  PAN PAGE  (single form — collect PAN + missing contact)    │
│                                                             │
│  1. GET /api/v2/profile/contact/                            │
│                                                             │
│  India (+91) phone or email → OTP flow → PAN verify        │
│  Non-India phone            → save phone (no OTP) → PAN    │
│  No contact needed          → PAN verify directly           │
│                                                             │
│  On success → status becomes "bank"                         │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│  ADDRESS PAGE  (new step — between PAN and Bank)            │
│                                                             │
│  GET /api/v2/profile/details/                               │
│    → data.address_info.pan_address (pre-fill or empty)      │
│                                                             │
│  User confirms / edits correspondence address               │
│                                                             │
│  PATCH /api/v2/profile/update/                              │
│    { extended_profile: { address_line_1, city, ... } }      │
│                                                             │
│  On success → navigate to bank page (still status "bank")   │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│  BANK PAGE  (UPI or manual + residency picker)              │
│                                                             │
│  GET  /api/v2/profile/bank/                                 │
│                                                             │
│  UPI:    POST /bank/upi/lookup/  → show review screen       │
│          POST /bank/upi/confirm/ { upi_id, investor_residency, ... }
│                                                             │
│  Manual: POST /bank/manual/      { account_number, ifsc_code,
│                                    investor_residency, ... } │
│                                                             │
│  On success → status becomes "profile"                      │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│  PROFILE PAGE  (two internal sub-steps)                     │
│                                                             │
│  GET /api/v2/profile/details/  → check address_info flags  │
│                                                             │
│  Sub-step 1 "postbank":                                     │
│    Resident  → read-only summary + draw signature           │
│    NRI       → overseas address + TIN + draw signature      │
│    Resident with foreign address → must correct to Indian   │
│                                                             │
│  Sub-step 2 "extras" (always shown after postbank):         │
│    Gender, occupation, income slab, place of birth, PEP     │
│                                                             │
│  PATCH /api/v2/profile/update/ { extended_profile: { ... } }│
│    On complete → status becomes "ucc"                       │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
    Dashboard  (status = "ucc" or "order")
```

---

## Onboarding Status

`GET /api/v1/auth/status/` — always call after login and after each step.  
The server auto-corrects stale status against actual verification state.

| `status` | Meaning | Primary route |
|----------|---------|---------------|
| `pan` | PAN not verified | `/onboarding/pan` |
| `bank` | PAN verified; bank not done | `/onboarding/address` then `/onboarding/bank` |
| `profile` | Bank verified; profile incomplete | `/onboarding/profile` |
| `ucc` | Profile complete; UCC pending | `/` (dashboard) |
| `order` | UCC active; can trade | `/` (dashboard) |

**Route gating for `bank` status:** the address step comes first. Allow both `/onboarding/address` and `/onboarding/bank` while status is `bank`. Redirect `/onboarding/bank` → `/onboarding/address` if user tries to skip the address step.

---

## Authentication (apiv1)

### POST `/api/v1/auth/login/`

Send OTP to phone or email. No auth required.

**Request:**
```json
{ "identifier": "9876543210" }
```
or
```json
{ "identifier": "user@example.com" }
```

**Response 201:**
```json
{
  "success": true,
  "type": "phone",
  "message": "OTP sent successfully"
}
```
`type` is `"phone"` or `"email"`.

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | Invalid phone / email format |
| `503` | SMS or email provider unavailable |

---

### POST `/api/v1/auth/verify/`

Verify OTP and receive JWT tokens. No auth required.

**Request:**
```json
{
  "identifier": "9876543210",
  "otp": "123456"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access": "<jwt_access_token>",
    "refresh": "<jwt_refresh_token>",
    "user": {
      "id": "uuid-string",
      "name": "John Doe",
      "email": "john@example.com",
      "phone_number": "9876543210"
    }
  }
}
```

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | Invalid or expired OTP |
| `400` | User not found — request OTP first |

---

### POST `/api/v1/auth/refresh/`

Exchange a refresh token for a new access token. No auth required.

**Request:**
```json
{ "refresh_token": "<refresh_token>" }
```

**Response 200:**
```json
{ "success": true, "access_token": "<new_access_token>" }
```

**Errors:**
| HTTP | Message | Action |
|------|---------|--------|
| `401` | Refresh token expired | Redirect to login |
| `401` | Session expired | Token revoked — redirect to login |
| `401` | Invalid refresh token | Redirect to login |

---

### GET `/api/v1/auth/status/`

Returns the current (server-reconciled) onboarding status.

**Response 200:**
```json
{ "success": true, "status": "bank" }
```

The server compares stored status against real verification state and corrects stale values before responding.

---

## PAN Page

One form that collects **PAN + any missing contact** side-by-side.

---

### GET `/api/v2/profile/contact/`

Check whether a secondary contact (phone or email) must be collected before PAN verify.

**Response 200 — contact missing:**
```json
{
  "success": true,
  "data": {
    "needs_secondary_otp": true,
    "secondary_kind": "phone",
    "phone_country_code": "+91"
  }
}
```

**Response 200 — no contact needed:**
```json
{
  "success": true,
  "data": {
    "needs_secondary_otp": false,
    "secondary_kind": null,
    "phone_country_code": null
  }
}
```

| Field | Type | Meaning |
|-------|------|---------|
| `needs_secondary_otp` | boolean | `true` = show contact field on PAN page |
| `secondary_kind` | `"phone"` \| `"email"` \| null | What to collect |
| `phone_country_code` | string \| null | Pre-fill the country code picker when `secondary_kind = "phone"` |

---

### POST `/api/v2/profile/contact/otp/`

Send OTP to an **Indian (+91) phone** or **email**. Skip entirely for non-Indian phones.

**Request:**
```json
{ "kind": "phone", "value": "9876543210" }
```
or
```json
{ "kind": "email", "value": "user@example.com" }
```

**Response 201:**
```json
{ "success": true, "message": "OTP sent to phone." }
```

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | `value` missing or invalid format |
| `503` | SMS / email provider unavailable |

---

### POST `/api/v2/profile/contact/otp/verify/`

Verify OTP and permanently save the contact on the user account.

**Request:**
```json
{
  "kind": "phone",
  "value": "9876543210",
  "otp": "123456"
}
```

**Response 200:**
```json
{ "success": true, "message": "Contact verified and saved." }
```

**After success:** Immediately call `POST /api/v2/profile/pan/verify/`.

**Errors:**
| HTTP | `code` | Message |
|------|--------|---------|
| `400` | — | Invalid or expired OTP |
| `409` | `phone_exists` | Phone already registered to another account |
| `409` | `email_exists` | Email already registered to another account |

---

### POST `/api/v2/profile/contact/phone/save/`

Save a **non-Indian phone** without OTP. Use only when `country_code != "+91"`.

**Request:**
```json
{
  "country_code": "+1",
  "phone_number": "2025551234"
}
```

**Response 200:**
```json
{ "success": true, "message": "Phone saved." }
```

**After success:** Immediately call `POST /api/v2/profile/pan/verify/`.

**Errors:**
| HTTP | `code` | Message |
|------|--------|---------|
| `400` | — | Missing fields or `country_code` is `+91` (use OTP instead) |
| `409` | `phone_exists` | Number already registered to another account |

---

### POST `/api/v2/profile/pan/verify/`

Verify PAN against bureau records (Cashfree PAN360). Also seeds name, DOB, email, gender, and address from KYC into the user's profile.

**Request:**
```json
{ "pan_number": "ABCDE1234F" }
```

**Response 200:**
```json
{
  "success": true,
  "message": "PAN verified.",
  "data": {
    "onboarding_status": "bank",
    "pan_number": "ABCDE1234F",
    "kyc_id": 42,
    "kyc_status": "VALID",
    "is_name_matched": true,
    "is_dob_matched": true,
    "name_at_source": "JOHN DOE",
    "dob_at_source": "1990-01-15",
    "prefilled_from_db": false
  }
}
```

| Field | Notes |
|-------|-------|
| `onboarding_status` | Always `"bank"` on success |
| `kyc_status` | `"VALID"` on success |
| `name_at_source` | Legal name from bureau |
| `dob_at_source` | DOB from bureau (`YYYY-MM-DD`) |
| `prefilled_from_db` | `true` = PAN found in internal holder records, no bureau call |

**After success:** Navigate to `/onboarding/address` (not bank directly — address step comes first).

**Errors:**
| HTTP | `code` | Message | Action |
|------|--------|---------|--------|
| `400` | — | PAN must be 10 characters | Validate client-side first |
| `400` | `contact_missing` | Phone/email not collected yet | Re-show contact field |
| `403` | — | PAN already verified | Show "already done" UI |
| `409` | `user_pan_exists` | Account already has a verified PAN | Advance to address page |
| `409` | `pan_exists` | PAN registered to different account | Ask user to contact support |
| `500` | — | Bureau call failed | Show retry |

---

### GET `/api/v2/profile/pan/`

Read-only PAN + bank state.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "pan_verified": true,
    "bank_verified": false,
    "next_step": "bank",
    "pan_number_masked": "ABCXX1234F",
    "primary_bank": null
  }
}
```

---

## Address Page

This is a **new step** between PAN and Bank (added to the flow). It loads the PAN registry address snapshot and lets the user confirm or correct their correspondence address before bank verification.

**Status at this step:** `"bank"` — the status does not change after saving the address.

---

### GET `/api/v2/profile/details/`

Use this to load the address page. Read `data.ucc_profile` for the currently saved address fields, and `data.address_info` for guidance flags.

Full response shape is documented in the **Profile Page** section below — the same endpoint is reused. Key fields for the address page:

```json
{
  "success": true,
  "onboarding_status": "bank",
  "data": {
    "ucc_profile": {
      "address_line_1": "123 Main St",
      "address_line_2": "Area",
      "address_line_3": "",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400001",
      "country": "IND"
    },
    "address_info": {
      "pan_address": {
        "address_line_1": "123 Main St",
        "address_line_2": "Area",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001",
        "country": "IND",
        "synced_at": "2024-01-15T10:30:00Z",
        "was_empty": false
      },
      "can_use_pan_address_as_current": true,
      "needs_indian_address": false,
      "guidance": "Address pre-filled from your PAN records. Confirm or edit it before continuing."
    }
  }
}
```

**Pre-fill logic for the address form:**

1. Try `data.ucc_profile.address_line_1` etc. first (already-saved correspondence address).
2. If empty, fall back to `data.address_info.pan_address` fields.
3. If `data.address_info.pan_address.was_empty` is `true`, the PAN registry returned no address — show a banner ("PAN registry had no address on file") and leave the form blank for manual entry.
4. If `data.address_info.pan_address` is `null`, PAN address was never fetched.

---

### PATCH `/api/v2/profile/update/`

Save the correspondence address. Use `extended_profile` dict — all UCC field names go inside it.

**Request:**
```json
{
  "extended_profile": {
    "address_line_1": "123 Main Street",
    "address_line_2": "Bandra West",
    "address_line_3": "",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400050",
    "country": "IND"
  }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `address_line_1` | Yes | Flat / building / street |
| `address_line_2` | No | Area / locality |
| `address_line_3` | No | Landmark |
| `city` | Yes | City name |
| `state` | Yes | State name |
| `pincode` | Yes | 6-digit Indian PIN or foreign postal code |
| `country` | Yes | 3-letter ISO code — `"IND"` for India, `"USA"`, `"GBR"` etc. for foreign |

**Response 200:**
```json
{
  "success": true,
  "onboarding_status": "bank",
  "data": {
    "status": "ok",
    "user": {
      "ucc_profile": {
        "address_line_1": "123 Main Street",
        "address_line_2": "Bandra West",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400050",
        "country": "IND"
      },
      "address_info": {
        "correspondence_address": {
          "address_line_1": "123 Main Street",
          "city": "Mumbai",
          "state": "Maharashtra",
          "pincode": "400050",
          "country": "IND"
        },
        "needs_indian_address": false,
        "needs_overseas_address": false
      },
      "profile_complete": false,
      "onboarding_status": "bank"
    }
  }
}
```

**After success:** Navigate to `/onboarding/bank`. Status is still `"bank"`.

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | Invalid JSON body |
| `400` | `extended_profile` must be a JSON object |

---

## Bank Page

### GET `/api/v2/profile/bank/`

Returns current bank state.

**Response — bank not yet verified:**
```json
{
  "success": true,
  "data": {
    "bank_verified": false,
    "primary_bank": null,
    "suggested_flow": "collect_bank",
    "collect_bank": {
      "upi_lookup_first": true,
      "manual_fallback": true,
      "hint": "If the user has no UPI ID, open the manual bank form."
    }
  }
}
```

**Response — bank already verified:**
```json
{
  "success": true,
  "data": {
    "bank_verified": true,
    "primary_bank": {
      "id": 1,
      "bank_name": "HDFC Bank",
      "account_number": "XXXXXXXX1234",
      "ifsc_code": "HDFC0001234",
      "upi_id": "user@hdfc",
      "account_type": "savings",
      "is_verified": true
    },
    "suggested_flow": "dashboard"
  }
}
```

**Errors:**
| HTTP | Message |
|------|---------|
| `403` | PAN must be verified first (`data.next_step = "pan"`) |

---

### POST `/api/v2/profile/bank/upi/lookup/`

Fetch bank account details from a UPI ID via Cashfree penny-drop. **Does not save anything.** The result is cached server-side for 5 minutes — confirm uses the cache so no second penny-drop within that window.

**Request:**
```json
{ "upi_id": "user@oksbi" }
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "fetched": {
      "upi_id": "user@oksbi",
      "account_holder_name": "John Doe",
      "name_at_bank": "John Doe",
      "bank_name": "State Bank of India",
      "account_number": "12345678901",
      "ifsc_code": "SBIN0001234",
      "account_type": "savings",
      "verification_status": "VALID",
      "message": ""
    }
  }
}
```

Only allow proceeding to confirm when `verification_status === "VALID"`. Show `account_holder_name`, `bank_name`, and masked `account_number` to the user. Let the user pick residency on this review screen before confirming.

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | VPA not found or penny-drop failed |
| `403` | PAN must be verified first |

---

### POST `/api/v2/profile/bank/upi/confirm/`

Save the UPI-verified bank as the primary bank. Uses cached penny-drop result if within 5 minutes.

**Request:**
```json
{
  "upi_id": "user@oksbi",
  "bank_name": "State Bank of India",
  "account_type": "savings",
  "investor_residency": "Resident"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `upi_id` | Yes | Must match the VPA used in lookup |
| `bank_name` | No | Display name (use what Cashfree returned) |
| `account_type` | No | `"savings"` or `"current"` |
| `investor_residency` | Yes | `"Resident"`, `"NRI-NRE"`, or `"NRI-NRO"` |

**Response 200:**
```json
{
  "success": true,
  "data": {
    "bank": {
      "id": 1,
      "bank_name": "State Bank of India",
      "account_number": "XXXXXXXX901",
      "ifsc_code": "SBIN0001234",
      "upi_id": "user@oksbi",
      "account_type": "savings",
      "is_verified": true
    },
    "next_step": "profile",
    "onboarding_status": "profile"
  }
}
```

**After success:** Navigate to `/onboarding/profile`. Status is now `"profile"`.

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | `upi_id` missing or does not match lookup |
| `400` | `investor_residency` required |
| `403` | PAN must be verified first |
| `502` | Cashfree service error |

---

### POST `/api/v2/profile/bank/manual/`

Save bank via account number + IFSC. Cashfree sync verification is run automatically.

**Request:**
```json
{
  "account_number": "12345678901234",
  "ifsc_code": "HDFC0001234",
  "bank_name": "HDFC Bank",
  "account_type": "savings",
  "investor_residency": "NRI-NRE"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `account_number` | Yes | Full bank account number |
| `ifsc_code` | Yes | 11-character IFSC code |
| `bank_name` | No | Display name |
| `account_type` | No | `"savings"` or `"current"` |
| `investor_residency` | Yes | `"Resident"`, `"NRI-NRE"`, or `"NRI-NRO"` |

**Response 200:**
```json
{
  "success": true,
  "data": {
    "bank": {
      "id": 1,
      "bank_name": "HDFC Bank",
      "account_number": "XXXXXXXXX234",
      "ifsc_code": "HDFC0001234",
      "account_type": "savings",
      "is_verified": true
    },
    "next_step": "profile",
    "name_at_bank": "JOHN DOE",
    "onboarding_status": "profile"
  }
}
```

`name_at_bank` — account holder name from Cashfree. Display it to the user.  
`next_step` — `"profile"` when verified, `"bank"` if Cashfree rejected but bank was saved unverified.

**After success (`is_verified: true`):** Navigate to `/onboarding/profile`. Status is `"profile"`.

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | Missing required fields or Cashfree rejected the account |
| `403` | PAN must be verified first |

---

## Profile Page

Two internal sub-steps rendered on the same route (`/onboarding/profile`):

1. **Postbank** — collect signature (Resident) or overseas address + TIN + signature (NRI)
2. **Extras** — occupation, income slab, gender, place of birth, PEP (always shown after postbank)

Both sub-steps use the same two endpoints.

---

### GET `/api/v2/profile/details/`

Fetch the full profile. Read `address_info` flags to determine which postbank UI to show.

**Response 200 — full shape:**
```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "id": "uuid-string",
    "name": "John Doe",
    "email": "john@example.com",
    "phone_number": "9876543210",
    "pan_number": "ABCDE1234F",
    "dob": "1990-01-15",
    "investor_residency": "Resident",
    "validate": false,
    "profile_complete": false,
    "identity_verified": true,
    "profile_issues": [
      "Digital signature (draw in beta profile)"
    ],
    "onboarding_status": "profile",

    "ucc_profile": {
      "primary_first_name": "John",
      "primary_last_name": "Doe",
      "primary_email": "john@example.com",
      "primary_mobile": "9876543210",
      "primary_gender": "M",
      "primary_occupation": "01",
      "primary_income_slab": "33",
      "primary_pob": "",
      "primary_pep": "N",
      "primary_signature": "",
      "primary_tax_id": "",
      "address_line_1": "123 Main Street",
      "address_line_2": "Bandra West",
      "address_line_3": "",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400050",
      "country": "IND",
      "ind_address_line_1": "",
      "ind_address_line_2": "",
      "ind_city": "",
      "ind_state": "",
      "ind_pincode": ""
    },

    "address_info": {
      "pan_address": {
        "address_line_1": "123 Main Street",
        "address_line_2": "",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001",
        "country": "IND",
        "synced_at": "2024-01-15T10:30:00Z",
        "was_empty": false
      },
      "correspondence_address": {
        "address_line_1": "123 Main Street",
        "address_line_2": "Bandra West",
        "address_line_3": "",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400050",
        "country": "IND"
      },
      "indian_address": null,
      "residency": "Resident",
      "is_nri": false,
      "correspondence_is_indian": true,
      "has_overseas_address": false,
      "has_indian_address": false,
      "can_use_pan_address_as_current": true,
      "needs_overseas_address": false,
      "needs_indian_address": false,
      "guidance": "Indian correspondence address saved."
    },

    "default_bank": {
      "bank_name": "HDFC Bank",
      "account_number": "XXXXXXXX1234",
      "ifsc_code": "HDFC0001234"
    },

    "profile_requirements": { "...section-based checklist (internal use)..." },
    "payment_upi_id": "user@oksbi",
    "holders": []
  }
}
```

#### `address_info` flag reference

| Flag | Type | Meaning |
|------|------|---------|
| `pan_address` | object \| null | Raw PAN registry snapshot. `null` = never fetched. `was_empty: true` = Cashfree returned blank. |
| `correspondence_address` | object \| null | Current saved primary address (overseas for NRI, Indian for Resident). `null` = not yet set. |
| `indian_address` | object \| null | NRI secondary Indian address slot (`ind_*` fields). `null` = not set. |
| `is_nri` | boolean | `true` when `investor_residency` is `NRI-NRE` or `NRI-NRO`. |
| `has_overseas_address` | boolean | `true` when correspondence has a non-IND country. |
| `has_indian_address` | boolean | `true` when `ind_address_line_1` is set. |
| `needs_overseas_address` | boolean | `true` for NRI who has not yet set an overseas address. Show overseas address form. |
| `needs_indian_address` | boolean | `true` for Resident whose saved correspondence has a foreign country. Must correct to Indian address. |
| `can_use_pan_address_as_current` | boolean | `true` when PAN address matches saved correspondence (address pre-filled from PAN, not yet changed). |
| `guidance` | string | Human-readable hint for debugging — do not display literally to users. |

#### `ucc_profile` field reference

All profile data lives in `ucc_profile`. Use these exact keys in `extended_profile` when saving.

| Key | Notes |
|-----|-------|
| `primary_first_name` | Seeded from PAN KYC automatically |
| `primary_last_name` | Seeded from PAN KYC automatically |
| `primary_email` | Seeded from user email |
| `primary_mobile` | Seeded from user phone |
| `primary_gender` | `"M"` / `"F"` / `"O"` |
| `primary_occupation` | Code string `"01"`–`"09"` |
| `primary_income_slab` | Code string `"31"`–`"36"` |
| `primary_pob` | Place of birth (city name) |
| `primary_pep` | `"N"` / `"Y"` / `"R"` |
| `primary_signature` | PNG data URL (`data:image/png;base64,...`) — min 80 chars. Required. |
| `primary_tax_id` | Foreign TIN. Required for NRI. |
| `address_line_1` | Correspondence address line 1. Required for Resident. For NRI = overseas addr line 1. |
| `address_line_2` | Optional line 2 |
| `address_line_3` | Optional line 3 (landmark) |
| `city` | City |
| `state` | State / region |
| `pincode` | Postal code |
| `country` | 3-letter ISO (`"IND"`, `"USA"`, `"GBR"`, …). Must be non-IND for NRI correspondence. |
| `ind_address_line_1` | Indian address (NRI secondary slot). Auto-filled from PAN KYC when NRI. |
| `ind_address_line_2` | Optional |
| `ind_city` | Indian city |
| `ind_state` | Indian state |
| `ind_pincode` | Indian PIN code |

#### `profile_issues` entries

When `profile_complete` is `false`, `profile_issues` lists what is missing. Display these to the user.

Common values:
- `"Digital signature (draw in beta profile)"` — signature not set or too short
- `"Overseas country (not IND) on correspondence address"` — NRI has IND in country field
- `"Foreign tax ID (TIN)"` — NRI has no `primary_tax_id`
- `"Correspondence address line 1"` — Resident has no address
- `"City"` / `"State"` / `"Pincode"` — Resident address incomplete

---

### PATCH `/api/v2/profile/update/`

Save any profile fields. Only provided fields are updated — partial saves are safe. All UCC fields go inside the `extended_profile` object. Top-level keys (`investor_residency`, `dob`, `phone_number`) bypass `extended_profile`.

**General shape:**
```json
{
  "investor_residency": "Resident",
  "extended_profile": {
    "<ucc_profile_key>": "<value>"
  }
}
```

When `investor_residency` changes, the server automatically re-routes the PAN address snapshot between the correspondence slot (`address_line_*`) and the Indian slot (`ind_address_line_*`).

#### Postbank sub-step — Resident

Save signature only:

```json
{
  "extended_profile": {
    "primary_signature": "data:image/png;base64,iVBORw0KGgo..."
  }
}
```

#### Postbank sub-step — NRI (overseas address + TIN + signature)

```json
{
  "extended_profile": {
    "primary_tax_id": "US-SSN-or-TIN",
    "country": "USA",
    "address_line_1": "123 Oak Street",
    "address_line_2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "pincode": "10001",
    "primary_signature": "data:image/png;base64,iVBORw0KGgo..."
  }
}
```

`country` must be a non-`IND` 3-letter ISO code. Validation blocks if `country` is `"IND"` or missing for NRI.

#### Postbank sub-step — Resident with foreign address correction

If `address_info.needs_indian_address` is `true`, the user must save an Indian address before the signature step proceeds:

```json
{
  "extended_profile": {
    "address_line_1": "456 Park Road",
    "address_line_2": "Juhu",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400049",
    "country": "IND"
  }
}
```

After a successful save, re-fetch `GET /profile/details/` and confirm `address_info.needs_indian_address` is now `false` before proceeding to signature.

#### Extras sub-step (occupation, income, gender, POB, PEP)

```json
{
  "extended_profile": {
    "primary_gender": "M",
    "primary_occupation": "02",
    "primary_income_slab": "33",
    "primary_pob": "Mumbai",
    "primary_pep": "N"
  }
}
```

All fields are optional with safe defaults. Do not block submission if any are blank.

#### Profile update response (all sub-steps return same shape)

```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "status": "ok",
    "user": {
      "ucc_profile": {
        "primary_first_name": "John",
        "primary_last_name": "Doe",
        "primary_email": "john@example.com",
        "primary_signature": "data:image/png;base64,...",
        "address_line_1": "123 Main Street",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400050",
        "country": "IND"
      },
      "address_info": {
        "needs_indian_address": false,
        "needs_overseas_address": false,
        "has_overseas_address": false
      },
      "profile_complete": false,
      "identity_verified": true,
      "profile_issues": ["Digital signature (draw in beta profile)"],
      "onboarding_status": "profile",
      "validate": false
    }
  }
}
```

When `profile_complete` becomes `true`, the server advances `onboarding_status` from `"profile"` to `"ucc"`:

```json
{
  "success": true,
  "onboarding_status": "ucc",
  "data": {
    "status": "ok",
    "user": {
      "profile_complete": true,
      "onboarding_status": "ucc",
      "validate": true,
      "profile_issues": []
    }
  }
}
```

**After `onboarding_status` becomes `"ucc"`:** Call `GET /api/v1/auth/status/` and navigate to `/`.

**Errors:**
| HTTP | Message |
|------|---------|
| `400` | Invalid JSON body |
| `400` | `extended_profile` must be a JSON object |
| `400` | Any backend validation error — read `message` |

---

## Residency vs. Address — The 4 Cases

After the bank step, the system checks the user's `investor_residency` against the address they saved at the address page. The `address_info` flags tell you which case applies and what to show.

### Case 1 — Resident + Indian address (normal)

`address_info.is_nri = false`, `address_info.needs_indian_address = false`

Show read-only summary of verified details (name, PAN, DOB, email, phone, address, bank).  
Collect **signature only**.

### Case 2 — NRI + Indian address saved (address was Indian but residency is NRI)

`address_info.is_nri = true`, `address_info.needs_overseas_address = true`, `address_info.has_overseas_address = false`

The server automatically moved the Indian address to `ind_address_line_1` when NRI was selected at bank.  
Show `indian_address` block read-only (from PAN).  
**Require**: overseas address (`address_line_1` + non-IND `country`) + `primary_tax_id` + signature.  
Save all via postbank update call — overseas address goes into `address_line_1 / country` fields (not `ind_*`).

### Case 3 — NRI + Foreign address saved

`address_info.is_nri = true`, `address_info.has_overseas_address = true`

The foreign address from the address page is already in `address_line_1` with a non-IND country.  
Pre-fill the overseas address form with the saved values.  
Show `indian_address` block read-only (from PAN, if available).  
**Require**: confirm/edit overseas address + `primary_tax_id` + signature.

### Case 4 — Resident + Foreign address (entered wrong address)

`address_info.is_nri = false`, `address_info.needs_indian_address = true`

Show an amber correction block. The user must save a corrected Indian address **before** the signature step.  
Save Indian address: `extended_profile: { address_line_1, city, state, pincode, country: "IND" }`.  
After save, re-check `address_info.needs_indian_address` from the update response.  
Once `false`, show the signature form.

---

## Complete Step-by-Step Call Sequence

```
── LOGIN ──────────────────────────────────────────────────────────────
POST /api/v1/auth/login/          { identifier }
POST /api/v1/auth/verify/         { identifier, otp }  → { access, refresh }
GET  /api/v1/auth/status/                              → "pan" / "bank" / ...

── PAN PAGE ───────────────────────────────────────────────────────────
GET  /api/v2/profile/contact/
  └─ needs_secondary_otp: false
       → POST /api/v2/profile/pan/verify/ { pan_number }

  └─ needs_secondary_otp: true, secondary_kind: "phone", phone_country_code: "+91"
       → POST /api/v2/profile/contact/otp/          { kind:"phone", value }
       → [OTP screen]
       → POST /api/v2/profile/contact/otp/verify/   { kind, value, otp }
       → POST /api/v2/profile/pan/verify/            { pan_number }

  └─ needs_secondary_otp: true, secondary_kind: "phone", phone_country_code: "+1" (non-India)
       → POST /api/v2/profile/contact/phone/save/   { country_code, phone_number }
       → POST /api/v2/profile/pan/verify/            { pan_number }

  └─ needs_secondary_otp: true, secondary_kind: "email"
       → POST /api/v2/profile/contact/otp/          { kind:"email", value }
       → [OTP screen]
       → POST /api/v2/profile/contact/otp/verify/   { kind, value, otp }
       → POST /api/v2/profile/pan/verify/            { pan_number }

PAN verify success → navigate to /onboarding/address  (status = "bank")

── ADDRESS PAGE ───────────────────────────────────────────────────────
GET  /api/v2/profile/details/
  → read data.ucc_profile (address_line_1, city, ...) for pre-fill
  → read data.address_info.pan_address for PAN snapshot (was_empty flag)

PATCH /api/v2/profile/update/ {
  extended_profile: {
    address_line_1, address_line_2, address_line_3,
    city, state, pincode, country
  }
}

Success → navigate to /onboarding/bank  (status still "bank")

── BANK PAGE ──────────────────────────────────────────────────────────
GET  /api/v2/profile/bank/

  UPI path:
    POST /api/v2/profile/bank/upi/lookup/   { upi_id }
    → show review + residency picker
    POST /api/v2/profile/bank/upi/confirm/  {
      upi_id, bank_name, account_type, investor_residency
    }

  Manual path:
    POST /api/v2/profile/bank/manual/ {
      account_number, ifsc_code, bank_name, account_type, investor_residency
    }

Success → navigate to /onboarding/profile  (status = "profile")

── PROFILE PAGE — sub-step 1: POSTBANK ───────────────────────────────
GET  /api/v2/profile/details/
  → check address_info flags to decide which case applies

  Case 1 — Resident + Indian (normal):
    Show read-only summary
    PATCH /api/v2/profile/update/ {
      extended_profile: { primary_signature }
    }

  Case 2 / 3 — NRI (needs overseas address):
    Show overseas address form + TIN field
    PATCH /api/v2/profile/update/ {
      extended_profile: {
        primary_tax_id, country, address_line_1, address_line_2,
        city, state, pincode, primary_signature
      }
    }

  Case 4 — Resident + foreign address (needs correction):
    Show amber Indian address correction block first
    PATCH /api/v2/profile/update/ {
      extended_profile: {
        address_line_1, city, state, pincode, country: "IND"
      }
    }
    Re-check address_info.needs_indian_address from response
    When false → show signature form
    PATCH /api/v2/profile/update/ {
      extended_profile: { primary_signature }
    }

After postbank → always show extras sub-step (do NOT navigate to / yet)

── PROFILE PAGE — sub-step 2: EXTRAS ─────────────────────────────────
PATCH /api/v2/profile/update/ {
  extended_profile: {
    primary_gender, primary_occupation, primary_income_slab,
    primary_pob, primary_pep
  }
}

If response.onboarding_status becomes "ucc":
  GET  /api/v1/auth/status/   → confirm "ucc"
  navigate to /

── DONE ───────────────────────────────────────────────────────────────
User is on dashboard (status "ucc" or "order")
```

---

## BSE Code Reference

### Occupation codes (`primary_occupation`)

| Code | Label |
|------|-------|
| `01` | Business |
| `02` | Service — Private |
| `03` | Service — Government |
| `04` | Professional |
| `05` | Agriculturist |
| `06` | Retired |
| `07` | Housewife |
| `08` | Student |
| `09` | Others |

### Income slab codes (`primary_income_slab`)

| Code | Range |
|------|-------|
| `31` | Below ₹1 lakh |
| `32` | ₹1–5 lakh |
| `33` | ₹5–10 lakh |
| `34` | ₹10–25 lakh |
| `35` | ₹25 lakh–1 crore |
| `36` | Above ₹1 crore |

### Gender codes (`primary_gender`)

| Code | Label |
|------|-------|
| `M` | Male |
| `F` | Female |
| `O` | Other |

### PEP codes (`primary_pep`)

| Code | Label |
|------|-------|
| `N` | Not a PEP |
| `Y` | Yes — Politically Exposed Person |
| `R` | Related to a PEP |

---

## Error Code Reference

| `code` | HTTP | Endpoint | Meaning | Action |
|--------|------|----------|---------|--------|
| `contact_missing` | 400 | PAN verify | Phone or email not saved yet | Re-show contact field |
| `user_pan_exists` | 409 | PAN verify | Account already has a verified PAN | Advance to address page |
| `pan_exists` | 409 | PAN verify | PAN belongs to a different account | Show "contact support" |
| `phone_exists` | 409 | OTP verify / phone save | Phone already on another account | Ask user to try a different number |
| `email_exists` | 409 | OTP verify | Email already on another account | Ask user to try a different email |

---

## Edge Cases

**Email-signup users** have no phone. `GET /profile/contact/` returns `secondary_kind: "phone"`. Show phone field + country code picker alongside PAN. Send OTP for `+91`, call `/contact/phone/save/` for non-`+91`.

**Phone-signup users** have no email. `GET /profile/contact/` returns `secondary_kind: "email"`. Show email field alongside PAN.

**PAN registry returned no address** (`address_info.pan_address.was_empty: true`). Show a blue info banner: "PAN registry had no address on file — please enter manually." Leave form fields blank.

**PAN registry returned no address** (`address_info.pan_address: null`). PAN address was never fetched (rare). Leave form blank, no banner needed.

**Residency change at bank re-routes PAN address.** When `investor_residency` changes from Resident → NRI (or vice versa), the server automatically moves the stored PAN address between `address_line_*` (Resident correspondence) and `ind_address_line_*` (NRI Indian slot). You do not need to do anything special — just re-fetch `GET /profile/details/` after bank to see the updated state.

**Overseas fields for NRI:** Only pre-fill the overseas address form (`address_line_1`, `country` etc.) when `address_info.has_overseas_address` is `true`. If `false`, start the form empty — do not pre-fill with whatever happens to be in `ucc_profile.address_line_1` (it may contain the old Indian address before the server cleared it).

**UPI penny-drop cache:** Server caches the Cashfree response for 5 minutes after `/upi/lookup/`. If confirm is called within that window, no second Cashfree call is made.

**Profile optional fields:** `primary_gender`, `primary_occupation`, `primary_income_slab`, `primary_pep`, and `primary_pob` have BSE defaults if omitted. Do not block form submission if these are blank. Always show the extras step so users can fill them — even if the profile was already marked complete by postbank.

**`primary_signature` format:** Must be a PNG data URL: `data:image/png;base64,...`. Minimum length 80 characters. A canvas `.toDataURL("image/png")` call is sufficient. The backend validates minimum length only — not actual image validity.

**PAN verify after contact OTP:** If contact OTP succeeds but PAN verify fails (e.g. PAN already registered), the contact is permanently saved. Show only the PAN field for retry — do not ask for contact again.
