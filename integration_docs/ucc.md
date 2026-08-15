# Account / UCC API — request & response payloads

All paths below are mounted under your server’s **`/api/v1/`** prefix (see `pivotmoney_backend/urls.py`).

**Authentication:** every endpoint in this document requires a valid JWT **access** token.

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

These routes open a **mutual fund registration** with the exchange using the same backend flow as the web **beta UCC** tools. The app does **not** expose low-level “UCC” jargon in the path names; internal responses still include a `client_code` which is required for subsequent OTP verification steps.

**Prerequisites:** the logged-in user (primary holder) must have a **complete investment profile** for UCC onboarding—see **`profile.md`** for required fields (address, bank, signature, PAN, etc.). 

---

## 1. `POST /api/v1/account/create/`

Creates one or more mutual fund applications (UCC) and applies **nomination** details. Following creation, a **BSE verification code** is emailed to the primary user.

**Next step:** **`POST /account/otp_verify/`** with `purpose: "bse"`.

### Request Payload Example (Single Holder with Nominee)
```json
{
  "accounts": ["SI"],
  "nomination": {
    "choice": "provide",
    "nominees": [
      {
        "first_name": "ANIRBAN",
        "last_name": "ROY",
        "relation": "Neighbor",
        "percent": 100,
        "dob": "1998-03-07",
        "pan": "DVYPR5760J",
        "address_line_1": "Flat No 1404",
        "city": "Mumbai Suburban",
        "state": "Maharashtra",
        "pincode": "400071"
      }
    ]
  }
}
```

### Request Payload Example (Joint Holder with Nominee & Extended Profile)
```json
{
  "accounts": ["AS"],
  "secondary_holder": {
    "first_name": "ANIRBAN",
    "last_name": "ROY",
    "dob": "1998-03-07",
    "pan": "DVYPR5760J",
    "mobile": "9876543210",
    "email": "anirban@example.com",
    "tax_status": "Resident",
    "signature": "data:image/png;base64,..."
  },
  "nomination": {
    "choice": "provide",
    "nominees": [
      {
        "first_name": "JASH",
        "last_name": "KORADIA",
        "relation": "Friend",
        "percent": 100,
        "dob": "1995-12-10",
        "pan": "ABCDE1234F",
        "address_line_1": "123 Street",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001"
      }
    ]
  }
}
```

### Key Request Fields
| Field | Type | Required | Notes |
|--------|------|----------|--------|
| `accounts` | array | yes | e.g. `["SI"]`, `["AS"]`, or `["SI", "AS"]`. |
| `nomination` | object | yes | See nomination block below. |
| `secondary_holder` | object | if AS | Secondary holder details if not using `secondary_user_id`. |
| `secondary_user_id` | string | if AS | ID of another registered user. |
| `extended_profile` | object | no | Merged into primary user UCC profile. |

### `nomination` (choice = provide)
| Field | Type | Required | Notes |
|--------|------|----------|--------|
| `choice` | string | yes | Must be `"provide"`. |
| `nominees` | array | yes | 1–3 objects. **Percentages must total 100**. |

**Nominee Object Fields:**
- `first_name`, `last_name`, `middle_name` (optional)
- `dob` (YYYY-MM-DD), `relation`
- `percent` (Integer 1-100)
- `pan` (Required for adults)
- `is_minor` (Boolean)
- `aadhaar_last4` (Required if minor + no PAN)
- `address_line_1`, `city`, `state`, `pincode`
- `guardian` (Required if minor): `{ first_name, last_name, dob, pan }`

---

## 2. `POST /api/v1/account/create_without_nominee/`

Used for the **nominee opt-out** flow. No nomination data is required.

**Next step:** **`POST /account/otp_verify/`** with `purpose: "nominee_opt_out"`.

### Request Payload Example
```json
{
  "accounts": ["SI"]
}
```

---

## 3. NRI (NRE/NRO) Handling

The API fully supports NRI accounts. When a user's `investor_residency` (on their profile) or the `tax_status` (in the `secondary_holder` payload) is set to **`NRI-NRE`** or **`NRI-NRO`**, the following additional rules apply:

### Additional Required Fields for NRIs
| Field | Context | Notes |
|--------|---------|--------|
| `country` | `secondary_holder` or profile | **Must not be `IND`**. A valid foreign country code/name is required. |
| `tax_id` | `secondary_holder` or profile | Foreign Tax Identification Number (TIN) is mandatory for NRIs. |
| `ind_address_line_1` | Primary User Profile | For NRIs, the system also collects an **Indian correspondence address** in addition to the foreign one. |

### Payload Example (NRI Secondary Holder)
```json
{
  "accounts": ["AS"],
  "secondary_holder": {
    "first_name": "JOHN",
    "last_name": "DOE",
    "tax_status": "NRI-NRE",
    "country": "USA",
    "tax_id": "999-00-1111",
    "dob": "1985-05-20",
    "pan": "ABCDE1234F",
    "mobile": "1234567890",
    "email": "john.doe@example.com",
    "signature": "..."
  }
}
```

---

## 4. `POST /api/v1/account/otp_verify/`

Verifies the OTPs received via email. This endpoint is used for both the **Nominee Opt-out** confirmation and the final **BSE Exchange** submission.

### Request Payload Example
```json
{
  "client_codes": ["PM_SI_ABCD"],
  "otp": "123456",
  "purpose": "bse"
}
```

### Purpose Values
| Value | Use Case |
|--------|----------|
| `nominee_opt_out` | Used after `create_without_nominee`. Verifies the opt-out OTP and triggers the generation of the opt-out form. Following this, a **BSE exchange OTP** is sent. |
| `bse` | Used as the **final step** for both flows. Submits the account and nomination/opt-out documents to the exchange. |

---

## 4. Complete Flow Summaries

### Flow A: With Nominees
1.  **Call** `POST /account/create/` with `nominees`.
2.  **User receives** BSE Exchange OTP via email.
3.  **Call** `POST /account/otp_verify/` with `purpose: "bse"` and the OTP.
4.  Account is now activated at BSE.

### Flow B: Nominee Opt-Out
1.  **Call** `POST /account/create_without_nominee/`.
2.  **User receives** Opt-Out OTP via email.
3.  **Call** `POST /account/otp_verify/` with `purpose: "nominee_opt_out"` and the OTP.
4.  **User receives** second email with BSE Exchange OTP.
5.  **Call** `POST /account/otp_verify/` with `purpose: "bse"` and the second OTP.
6.  Account is now activated at BSE.

---

## 5. Implementation Details (Backend)

- **Step 1**: `add_ucc` handles the account creation and initial AOF.
- **Step 2**: `update_ucc` (Nomination Update) happens automatically during the `bse` purpose verification.
- **Step 3**: `update_ucc` (ELOG Attachment) is the final phase of activation.

For developers, these steps are abstracted behind the `otp_verify` call for the `bse` purpose. If a step fails, the response will include a `failed_at` identifier and `details` for debugging.
