# Profile API — request & response payloads

All paths below are mounted under your server’s **`/api/v1/`** prefix (see `pivotmoney_backend/urls.py`).

**Authentication:** every profile endpoint requires a valid JWT **access** token unless noted otherwise.

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```x

Onboarding status values (`UserStatus.status`) follow this order:

`pan` → `bank` → `profile` → `ucc` → `order`

- After **`POST /profile/pan_verify/`** (success): **`bank`**
- After **`POST /profile/bank_details/`** (success): from **`bank`** → **`profile`**
- After **`POST /profile/details_update/`** with **`submit_profile: true`** and a **complete** profile + verified PAN: **`profile`** → **`ucc`**

**`GET` and `POST` `/profile/bank_details/`** return **`onboarding_status`** at the **top level** and inside **`data`**.

**`/profile/details/`** and **`/profile/details_update/`** expose **`profile_issues`**, **`identity_verified`**, **`profile_complete`**, and **`profile_requirements`**. Send profile patches with **`extended_profile`** on **`details_update`** (see §6).

---

## 1. `GET /api/v1/profile/pan/`

**Request:** no body.

**Response `200`**

```json
{
  "success": true,
  "data": {
    "name": "",
    "pan_number": "",
    "dob": ""
  }
```

- `dob` is `YYYY-MM-DD` when set, otherwise `""`.
- Values come from the authenticated `User` row.

---

## 2. `POST /api/v1/profile/pan_verify/`

Runs Cashfree **PAN 360 / advance** only (`POST …/pan/advance`) via `kyc_verification.views.perform_pan360_kyc_verification`:

- Up to **3 HTTP attempts** if Cashfree returns a **transient** error (timeouts, non-JSON, 5xx, etc.).
- If all attempts fail with transient errors → **`400`** with message *“Cashfree verification service is not responding…”* (a `KYCVerification` row may still be stored with `status` `ERROR`).
- **PAN lite** (`/pan`) is **not** called by default; if PAN 360 returns `VALID` but **`father_name`** is missing, **one** lite call is made to enrich the payload before saving.
- Results are stored in **`kyc_verification.KYCVerification`** (`raw_response`, `verification_type` `PAN_ADVANCE` or `PAN_LITE_AND_ADVANCE` when lite was merged).
- **Name match** uses the same logic as the rest of KYC: names are compared after normalising to **uppercase tokens** (bureau often returns ALL CAPS; the app may send Title Case).
- **DOB match** compares your `YYYY-MM-DD` date to Cashfree’s `date_of_birth` / `dob` (supports `DD-MM-YYYY` and similar). Both **name** and **DOB** must match for overall success.
- On full success, onboarding moves to **`bank`** and `User` is updated (PAN, DOB, display name from bureau) like `_apply_kyc_match_to_user`.

**Request body (JSON)**

| Field | Type | Required | Notes |
|--------|------|----------|--------|
| `name` | string | yes | As on PAN; stored/display title-cased where applicable |
| `pan_number` | string | yes | 10 characters, A–Z + digits |
| `dob` | string | yes | `YYYY-MM-DD` |

Example:

```json
{
  "name": "Rahul Kumar Sharma",
  "pan_number": "ABCDE1234F",
  "dob": "1990-01-15"
}
```

**Response `200` (PAN VALID + name matched + DOB matched)**

```json
{
  "success": true,
  "message": "Identity verified successfully! Records match 'Rahul Kumar Sharma'.",
  "data": {
    "onboarding_status": "bank",
    "pan_number": "ABCDE1234F",
    "kyc_id": 42,
    "kyc_status": "VALID",
    "is_name_matched": true,
    "is_dob_matched": true,
    "name_at_source": "Rahul Kumar Sharma",
    "dob_at_source": "15-01-1990"
  }
}
```

**Response `400` (invalid PAN, name/DOB mismatch, non-transient Cashfree error, or service unavailable after retries)**

```json
{
  "success": false,
  "message": "<human-readable reason>",
  "data": {}
}
```

When a `KYCVerification` row was created/updated, `data` typically includes:

| Field | Meaning |
|--------|--------|
| `kyc_id` | Primary key of the new verification row |
| `kyc_status` | e.g. `VALID`, `INVALID`, `ERROR` |
| `is_name_matched` | After normalisation, user name vs bureau name |
| `is_dob_matched` | User DOB vs bureau DOB |
| `name_at_source` | Name from PAN record (presentable form) |
| `dob_at_source` | DOB string from bureau |
| `name_mismatch` | `true` if `kyc_status` is `VALID` but name did not match |
| `dob_mismatch` | `true` if `kyc_status` is `VALID` but DOB did not match |

**Response `500`**

```json
{
  "success": false,
  "message": "An unexpected error occurred: …",
  "data": {}
}
```

---

## 3. `GET /api/v1/profile/bank_details/`

**Request:** no body.

**Response `200`**

```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "account_number": "",
    "ifsc_code": "",
    "bank_type": "",
    "bank_name": "",
    "upi_id": "",
    "onboarding_status": "profile"
  }
}
```

| Field | Source |
|--------|--------|
| `onboarding_status` (root and `data`) | Same value: `UserStatus.status` (e.g. `pan`, `bank`, `profile`, `ucc`, `order`) |
| `account_number`, `ifsc_code`, `bank_type`, `bank_name` | Default `UserBank` row, else `User.ucc_profile` draft (`bank_acc_num`, `ifsc_code`, `bank_acc_type`) |
| `upi_id` | Default `UserBank.upi_id`, else `ucc_profile["upi_id"]` or `ucc_profile["vpa"]` |

---

## 4. `POST /api/v1/profile/bank_details/`

Persists bank + UPI on the user record and default **`UserBank`** (including **`upi_id`**). If current status is **`bank`**, it moves to **`profile`** so the client can collect the rest of the profile next.

**Request body (JSON)**

| Field | Type | Required | Notes |
|--------|------|----------|--------|
| `account_number` | string | yes | Alias: `bank_acc_num` |
| `ifsc_code` | string | yes | 11 characters |
| `bank_type` | string | no | Default `SB`. Values: `SB`, `CB`, `NE`, `NO`. Alias: `bank_acc_type` |
| `upi_id` | string | no | Stored on `ucc_profile.upi_id` and synced to default `UserBank.upi_id` |
| `vpa` | string | no | Same meaning as `upi_id` if `upi_id` omitted |
| `bank_name` | string | no | Updates `UserBank.bank_name` when account exists |

Example:

```json
{
  "account_number": "123456789012",
  "ifsc_code": "HDFC0001234",
  "bank_type": "SB",
  "upi_id": "user@paytm",
  "bank_name": "HDFC Bank"
}
```

**Response `200`**

Same shape as **`GET`** after save. Example when onboarding moves **`bank`** → **`profile`**:

```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "account_number": "123456789012",
    "ifsc_code": "HDFC0001234",
    "bank_type": "SB",
    "bank_name": "HDFC Bank",
    "upi_id": "user@paytm",
    "onboarding_status": "profile"
  }
}
```

If status was already **`profile`**, **`ucc`**, or **`order`**, it is left unchanged (only **`bank`** advances to **`profile`** here).

**Response `400`**

```json
{
  "success": false,
  "message": "account_number and ifsc_code are required.",
  "data": {}
}
```

or

```json
{
  "success": false,
  "message": "IFSC must be 11 characters.",
  "data": {}
}
```

---

## 5. `GET /api/v1/profile/details/`

**Request:** no body.

Returns the signed-in user’s stored profile plus validation helpers: **`profile_issues`**, **`identity_verified`**, **`profile_complete`**, and **`profile_requirements`** (what is required vs optional for the current **`investor_residency`**).

**Response `200`**

```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "id": "<uuid string>",
    "name": "",
    "phone_number": "",
    "pan_number": "",
    "dob": "YYYY-MM-DD",
    "email": "",
    "investor_residency": "Resident | NRI-NRE | NRI-NRO | null",
    "ucc_profile": {},
    "default_bank": {
      "id": 1,
      "account_number": "",
      "ifsc_code": "",
      "bank_name": "",
      "account_type": "",
      "upi_id": "",
      "is_default": true
    },
    "created_at": "<iso8601>",
    "updated_at": "<iso8601>",
    "kyc": {},
    "kyc_done": false,
    "needs_kyc_verification": true,
    "kyc_name_mismatch": false,
    "name_suggested_from_pan": null,
    "ucc_accounts": [],
    "onboarding_status": "profile",
    "profile_issues": ["First name", "Digital signature (PNG data URL, required for agreements)"],
    "identity_verified": false,
    "profile_complete": false,
    "profile_requirements": {
      "investor_residency": "Resident",
      "sections": [
        {
          "id": "investor_type",
          "title": "Investor type",
          "required": [],
          "optional": []
        },
        {
          "id": "account",
          "title": "Account (stored on user)",
          "required": [],
          "optional": []
        },
        {
          "id": "correspondence",
          "title": "Correspondence address",
          "required": [],
          "optional": []
        },
        {
          "id": "bank",
          "title": "Bank (default)",
          "required": [],
          "optional": []
        },
        {
          "id": "signatures",
          "title": "Digital signatures",
          "required": [],
          "optional": []
        }
      ],
      "optional_field_keys": [],
      "notes": []
    }
  }
}
```

| Field | Meaning |
|--------|--------|
| `onboarding_status` | `UserStatus.status` |
| `profile_issues` | Missing required fields until the profile is complete (empty when none) |
| `identity_verified` | Same as `kyc_done`: PAN check `VALID` and name matched |
| `profile_complete` | `true` when `identity_verified` and `profile_issues` is empty |
| `profile_requirements` | **Sections** matching the profile screen: investor type → account (user row + extended fields) → correspondence → bank → signatures. Each section has **`required`** and **`optional`** field descriptors (`key`, `in`, `label`, optional `note`). For **NRI-NRE / NRI-NRO**, an extra **Indian address (optional)** section is included. **`optional_field_keys`** is a flat list of keys that never block completion. **`notes`** explain partial updates. Actual completion still follows **`profile_issues`** / **`profile_complete`**. |

**`onboarding_status`** at the **root** (next to `success`) duplicates **`data.onboarding_status`** so clients can read either location (e.g. after **`submit_profile`** success it is **`ucc`**).

The stored extended profile is returned under **`ucc_profile`** for backward compatibility with existing clients. New clients should send updates using **`extended_profile`** on **`POST /profile/details_update/`** (see §6).

**Response `500`**

```json
{
  "success": false,
  "message": "<exception message>",
  "data": {}
}
```

---

## 6. `POST /api/v1/profile/details_update/`

Saves fields from the JSON body, then returns the updated user. The body must be valid JSON.

**Partial updates:** only include keys you want to change. Optional extended-profile keys you **omit** are left as already stored (they are not cleared). To remove a signature, send `null` for that key inside `extended_profile` / merged profile (see below).

### Extended profile payload: `extended_profile` (preferred)

Send nested fields inside **`extended_profile`**. The server merges this with any existing stored document before save. You may also send **`ucc_profile`** for backward compatibility; if **both** are present, keys in **`extended_profile`** win on conflict.

### Top-level body fields

| Field | Type | Notes |
|--------|------|--------|
| `investor_residency` | string | `Resident`, `NRI-NRE`, `NRI-NRO`, or empty / null to clear |
| `phone_number` | string | Digits; min 10; must be unique |
| `dob` | string / null | `YYYY-MM-DD` or null to clear |
| `pan_number` | string | 10 chars; must be unique |
| `name` | string | Non-empty updates display name |
| `extended_profile` | object | **Preferred** — see tables below |
| `ucc_profile` | object | Legacy alias of the same document |
| `submit_profile` | boolean | Default `false`. If `true`, after save the server checks completeness and may advance onboarding. |
| `submit_for_ucc` | boolean | Deprecated alias for `submit_profile`. |

### When is each thing required? (same rules as server profile tools)

**All investors (`Resident`, `NRI-NRE`, `NRI-NRO`):**

| Area | Required for a “complete” profile | Where |
|------|-----------------------------------|--------|
| Name | First & last name | `extended_profile.primary_first_name`, `primary_last_name` |
| Identity | DOB, PAN, phone (10+ digits) | `dob`, `pan_number`, `phone_number` |
| Email | Email | `extended_profile.primary_email` (also updates account email when set) |
| Residency | One of `Resident` / `NRI-NRE` / `NRI-NRO` | `investor_residency` |
| Signature | PNG data URL, minimum length enforced server-side | `extended_profile.primary_signature` |
| Bank | Account number, IFSC, type `SB`/`CB`/`NE`/`NO` | Prefer **`POST /api/v1/profile/bank_details/`**; or `bank_acc_num`, `ifsc_code`, `bank_acc_type` in `extended_profile` |

**Resident only — Indian correspondence (in addition to the above):**

| Field | Notes |
|--------|--------|
| `address_line_1`, `city`, `state`, `pincode` | Required |
| `country` | Typically `IND` |

**NRI-NRE and NRI-NRO (same rules) — in addition to the “all investors” list:**

| Field | Notes |
|--------|--------|
| `primary_tax_id` | **Foreign TIN — required** |
| `country` | On correspondence address — **required, must not be `IND`** (overseas address uses correspondence lines) |
| `address_line_1`, `city`, `state`, `pincode` | **Required** (overseas correspondence) |

**Optional for NRIs (do not block completion):**

| Field | Notes |
|--------|--------|
| `ind_address_line_1`, `ind_city`, `ind_state`, `ind_pincode` | Indian address — optional |

### Optional extended-profile fields (any investor)

If the client does not send them, previous values remain. Safe to omit on partial saves.

| Key | Notes |
|-----|--------|
| `primary_middle_name` | Optional name part |
| `primary_mobile` | Extra mobile if different from account phone |
| `primary_gender` | `M` / `F` / `O` |
| `primary_occupation` | e.g. `01`–`08` |
| `primary_income_slab` | e.g. `31`–`35` |
| `primary_pob`, `primary_pep` | Place of birth; PEP `N` / `Y` / `R` |
| `address_line_2`, `address_line_3` | Extra address lines |
| `secondary_signature` | Joint-holder flows |
| `bank_acc_num`, `ifsc_code`, `bank_acc_type` | If not using the bank-details endpoint |

### Example — Resident (partial)

```json
{
  "investor_residency": "Resident",
  "phone_number": "9876543210",
  "dob": "1990-01-15",
  "pan_number": "ABCDE1234F",
  "name": "Rahul Sharma",
  "extended_profile": {
    "primary_first_name": "Rahul",
    "primary_last_name": "Sharma",
    "primary_email": "rahul@example.com",
    "address_line_1": "12 MG Road",
    "city": "Mumbai",
    "state": "MH",
    "pincode": "400001",
    "country": "IND"
  },
  "submit_profile": false
}
```

### Example — NRI (foreign correspondence + TIN)

```json
{
  "investor_residency": "NRI-NRE",
  "extended_profile": {
    "primary_tax_id": "AB123456C",
    "country": "USA",
    "address_line_1": "100 Main St",
    "city": "New York",
    "state": "NY",
    "pincode": "10001",
    "ind_address_line_1": "Optional Indian address line"
  },
  "submit_profile": false
}
```

Use **`GET /profile/details/`** → **`profile_requirements`** for the live checklist for the logged-in user (arrays are structured for UI).

### `submit_profile: false` (default)

**Response `200`**

```json
{
  "success": true,
  "onboarding_status": "profile",
  "data": {
    "status": "ok",
    "user": {}
  }
}
```

**`onboarding_status`** at the root matches **`data.user.onboarding_status`**. `data.user` also includes `profile_issues`, `identity_verified`, `profile_complete`, and **`profile_requirements`** (same idea as **`GET /profile/details/`**).

### `submit_profile: true`

After a successful save, the server requires **`profile_complete`** (`identity_verified` and empty **`profile_issues`**).

**Response `200`**

```json
{
  "success": true,
  "onboarding_status": "ucc",
  "data": {
    "status": "ok",
    "user": {},
    "message": "Your profile is verified. You can continue to the next step."
  }
}
```

- Root **`onboarding_status`** is **`ucc`** (same as **`data.user.onboarding_status`**).
- Onboarding moves to **`ucc`** (next step in the product flow).
- `user.profile_issues` is empty; `user.identity_verified` and `user.profile_complete` are `true`.

**Response `400` (not ready)**

```json
{
  "success": false,
  "message": "PAN verification must be complete with a matching name. Fill all required profile fields.",
  "data": {
    "profile_issues": ["…"],
    "identity_verified": false,
    "profile_complete": false,
    "profile_requirements": {},
    "user": {}
  }
}
```

The save may already have been applied; fix issues and retry with `submit_profile: true` when ready.

### Save-layer validation errors (invalid values, duplicate phone, etc.)

**Response `4xx`/`5xx`**

```json
{
  "success": false,
  "message": "<reason when present>",
  "data": {
    "status": "error",
    "message": "…"
  }
}
```

(Error text uses **`extended_profile`** in place of internal storage names where applicable.)

**Response `400` — invalid JSON or bad `extended_profile` type**

```json
{
  "success": false,
  "message": "extended_profile must be a JSON object",
  "data": {}
}
```

```json
{
  "success": false,
  "message": "Invalid JSON body.",
  "data": {}
}
```

---

## Related code

| Piece | Location |
|--------|-----------|
| Profile views | `apiv1/views/profile.py` |
| Profile validation | `apiv1/views/profile.py` (helpers above `ProfileDetailsAPI`) |
| Profile persistence | `user.beta_views.beta_user_profile_api` |
| User serialization | `user.beta_views._serialize_user` |
