# Frontend API Reference — Complete (invest, search, orders, portfolio, SIP, sell, UCC, profile, holders, aggregators)

> **Scope:** every endpoint that `TestingFrontEnd` (`src/lib/*.js` + `MfInvestOrderWizard.jsx`) actually calls, documented from the live source code.
> **Auth unless noted:** `Authorization: Bearer <access_token>` header.
> **Base URL:** `VITE_API_BASE_URL` env var (empty = same-origin).
> **v1 prefix:** `/api/v1/` · **v2 prefix:** `/api/v2/`
> **Envelope:** every response is `{ "success": true|false, "message": "...", "data": { ... } }`
> **Decimals:** money fields are Django `Decimal` — stringified (e.g. `"5000.00"`). Use `Number(x)` or a decimal lib.

**Navigation:** Sections **1–23** are endpoint reference. Section **24** is the `MfInvestOrderWizard` call order. Sections **25–28** add **theory** (when to call what, onboarding vs UCC list, TestingFrontEnd vs `trade/setup`, path pitfalls) and do not replace the rest of the document.

---

## Table of contents

1. [Auth (apiv1)](#1-auth-apiv1)
2. [Profile validate — onboarding state machine (apiv2)](#2-profile-validate--onboarding-state-machine-apiv2)
3. [Contact OTP — phone &amp; email (apiv2)](#3-contact-otp--phone--email-apiv2)
4. [PAN verification (apiv2)](#4-pan-verification-apiv2)
5. [Bank setup — UPI lookup / confirm / manual (apiv2)](#5-bank-setup--upi-lookup--confirm--manual-apiv2)
6. [Investor residency (apiv2)](#6-investor-residency-apiv2)
7. [Profile details &amp; update (apiv2)](#7-profile-details--update-apiv2)
8. [Joint holders (apiv2)](#8-joint-holders-apiv2)
9. [Fund discovery — browse &amp; filters (apiv2)](#9-fund-discovery--browse--filters-apiv2)
10. [Fund detail (apiv2)](#10-fund-detail-apiv2)
11. [Dashboard mutual fund list (apiv2)](#11-dashboard-mutual-fund-list-apiv2)
12. [Portfolio holdings (apiv2)](#12-portfolio-holdings-apiv2)
13. [Order history &amp; detail (apiv2)](#13-order-history--detail-apiv2)
14. [UCC trade wizard — full flow (apiv2)](#14-ucc-trade-wizard--full-flow-apiv2)
15. [Payment poll config (apiv2)](#15-payment-poll-config-apiv2)
16. [Lumpsum buy — folio check, create order, pay (apiv1)](#16-lumpsum-buy--folio-check-create-order-pay-apiv1)
17. [E-mandate + mandate-linked SIP (apiv2)](#17-e-mandate--mandate-linked-sip-apiv2)
18. [Legacy SIP — create / pay / status (apiv1)](#18-legacy-sip--create--pay--status-apiv1)
19. [Sell / redeem (apiv1)](#19-sell--redeem-apiv1)
20. [MF Central &amp; Finarkein account aggregator (apiv2)](#20-mf-central--finarkein-account-aggregator-apiv2)
21. [Health check (apiv2)](#21-health-check-apiv2)
22. [HTTP status quick reference](#22-http-status-quick-reference)
23. [Frontend lib → endpoint matrix](#23-frontend-lib--endpoint-matrix)
24. [MfInvestOrderWizard step-by-step API flow](#24-mfinvestorderwizard-step-by-step-api-flow)
25. [Theory: when to call which API (onboarding, UCC, invest)](#25-theory-when-to-call-which-api-onboarding-ucc-invest)
26. [UCC onboarding vs order/accounts (trade-eligible list)](#26-ucc-onboarding-vs-orderaccounts-trade-eligible-list)
27. [TestingFrontEnd vs one-shot trade/setup](#27-testingfront-end-vs-one-shot-tradesetup)
28. [Common path mistakes (mobile / new clients)](#28-common-path-mistakes-mobile--new-clients)

---

## 1. Auth (apiv1)

All auth endpoints live under `/api/v1/auth/`. No `Authorization` header required for these.

### 1.1 `POST /api/v1/auth/login/`

Initiates login — sends an OTP to the user's registered phone or email.

| Body field                   | Required     | Notes                     |
| ---------------------------- | ------------ | ------------------------- |
| `phone_number` / `email` | One required | Identifier to send OTP to |

**200**

```json
{ "success": true, "message": "OTP sent." }
```

---

### 1.2 `POST /api/v1/auth/verify/`

Verifies OTP and returns JWT tokens.

| Body field                   | Required                             |
| ---------------------------- | ------------------------------------ |
| `otp`                      | Yes                                  |
| `phone_number` / `email` | Yes — same identifier used in login |

**200**

```json
{
  "success": true,
  "access": "<jwt access token>",
  "refresh": "<jwt refresh token>",
  "user": { "id": 1, "email": "...", "phone_number": "..." }
}
```

---

### 1.3 `POST /api/v1/auth/refresh/`

Exchanges a refresh token for a new access token. Called automatically by `fetchAuthed()` in all lib files on `401`.

| Body field  | Required |
| ----------- | -------- |
| `refresh` | Yes      |

**200**

```json
{ "access": "<new access token>" }
```

---

### 1.4 `GET /api/v1/auth/status/`

Light session check — returns current user state without a full profile fetch.

**200**

```json
{ "success": true, "data": { "authenticated": true, "user_id": 1 } }
```

---

## 2. Profile validate — onboarding state machine (apiv2)

### `GET /api/v2/profile/validate/`

**Auth:** JWT. Called by `getProfileValidate()` in `profileApi.js`. Drives the entire onboarding UI — tells the frontend which step to render next.

**See also (full detail):** [`onboarding_new.md`](onboarding_new.md) — **which screen / route to open** for each `next_step` (including `TestingFrontEnd` paths from `onboardingUtils.js` / `OnboardingRouter.jsx`) and **how the validate endpoint works internally** (state machine in `apiv2/views/profile_validate.py`: `_determine_onboarding_step` + per-entity `status` fields).

**200**

```
{
  "success": true,
  "data": {
    "next_step": "contact_and_pan | pan | address | bank | nri_address | ri_address | details | mf_central | financial_aggregator | complete",
    "context": {
      "needs_phone": false,
      "needs_email": false,
      "needs_indian_phone_verification": false,
      "prefill": { "pan": "ABCDE1234F", "name": "..." }
    },
    "pan":     { "status": "verified | pending" },
    "phone":   { "status": "verified | pending" },
    "email":   { "status": "verified | pending" },
    "bank":    { "status": "verified | pending" },
    "upi":     { "status": "verified | pending" },
    "address": { "status": "verified | pending" },
    "details": { "status": "verified | pending", "missing": ["dob", "gender"] },
    "mf_central":           { "status": "verified | pending" },
    "financial_aggregator": { "status": "verified | pending" }
  }
}
```

When `next_step` is `"complete"`, the user is fully onboarded and can trade.

---

## 3. Contact OTP — phone & email (apiv2)

### 3.1 `GET /api/v2/profile/contact/`

Returns current contact verification state. Called by `getContactStatus()`.

**200**

```json
{
  "success": true,
  "data": {
    "phone_verified": true,
    "email_verified": false,
    "phone_number": "+919876543210",
    "email": "user@example.com"
  }
}
```

---

### 3.2 `POST /api/v2/profile/contact/otp/`

Send OTP to phone or email. Called by `sendContactOtp()`.

| Body field | Required | Notes                          |
| ---------- | -------- | ------------------------------ |
| `kind`   | Yes      | `"phone"` or `"email"`     |
| `value`  | Yes      | The phone/email to send OTP to |

**201**

```json
{ "success": true, "message": "OTP sent to phone/email." }
```

---

### 3.3 `POST /api/v2/profile/contact/otp/verify/`

Verify OTP and save the contact. Called by `verifyContactOtp()`.

| Body field | Required                         |
| ---------- | -------------------------------- |
| `kind`   | Yes —`"phone"` or `"email"` |
| `value`  | Yes                              |
| `otp`    | Yes                              |

**200**

```json
{ "success": true, "message": "Contact verified and saved." }
```

**400** — invalid OTP or expired.

---

### 3.4 `POST /api/v2/profile/contact/phone/save/`

Save a non-Indian phone number (no OTP, direct save). Called by `saveContactPhone()`.

| Body field       | Required | Notes         |
| ---------------- | -------- | ------------- |
| `country_code` | Yes      | e.g.`"+44"` |
| `phone_number` | Yes      | Digits only   |

**200**

```json
{ "success": true, "message": "Phone saved." }
```

---

## 4. PAN verification (apiv2)

### 4.1 `GET /api/v2/profile/pan/`

Returns current PAN + bank verification state. Called by `getPanInfo()`.

**200**

```json
{
  "success": true,
  "data": {
    "pan_verified": true,
    "bank_verified": false,
    "next_step": "bank",
    "pan_number_masked": "ABCDE****F",
    "primary_bank": { "bank_name": "HDFC", "account_number": "••••1234" }
  }
}
```

---

### 4.2 `POST /api/v2/profile/pan/verify/`

Bureau-verify a PAN via Cashfree PAN360. Called by `verifyPanBureau()`. Returns name + DOB from NSDL/CDSL.

| Body field     | Required                             |
| -------------- | ------------------------------------ |
| `pan_number` | Yes — 10-char, e.g.`"ABCDE1234F"` |

**200**

```json
{
  "success": true,
  "message": "PAN verified.",
  "data": {
    "onboarding_status": "BANK",
    "pan_number": "ABCDE1234F",
    "kyc_id": 42,
    "kyc_status": "VALID",
    "is_name_matched": true,
    "is_dob_matched": true,
    "name_at_source": "JOHN DOE",
    "dob_at_source": "1990-01-01",
    "prefilled_from_db": false
  }
}
```

**400** — PAN format invalid, bureau failure.
**409** — PAN already registered to a different account.

---

## 5. Bank setup — UPI lookup / confirm / manual (apiv2)

### 5.1 `GET /api/v2/profile/bank/`

Current bank/UPI state for onboarding. Called by `getBankState()`.

**200**

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
      "hint": "Enter your UPI ID to fetch bank details"
    }
  }
}
```

---

### 5.2 `PATCH /api/v2/profile/bank/`

Update existing bank fields (partial). Called by `patchBank()`.

| Body field         | Required | Notes                            |
| ------------------ | -------- | -------------------------------- |
| `bank_name`      | No       | Bank name string                 |
| `account_type`   | No       | e.g.`"SB"` (savings)           |
| `upi_id`         | No       | VPA string e.g.`"user@okaxis"` |
| `account_number` | No       | Full account number              |
| `ifsc_code`      | No       | 11-char IFSC                     |

**200** → `{ "success": true, "data": { "bank": { ... } } }`

---

### 5.3 `POST /api/v2/profile/bank/upi/lookup/`

Penny-drop: look up account details from UPI ID via Cashfree — **does not save**. Result cached 5 minutes for confirm step. Called by `bankUpiLookup()`.

| Body field            | Required | Notes                 |
| --------------------- | -------- | --------------------- |
| `upi_id` or `vpa` | Yes      | e.g.`"name@okaxis"` |

**200**

```json
{
  "success": true,
  "data": {
    "fetched": {
      "verification_status": "VALID",
      "bank_name": "AXIS BANK",
      "account_number": "9876543210",
      "name_at_bank": "JOHN DOE"
    }
  }
}
```

**400** — invalid VPA format.
**422** — Cashfree lookup failed (UPI not registered / bank error).

---

### 5.4 `POST /api/v2/profile/bank/upi/confirm/`

Confirm the looked-up UPI account and save as primary bank. Called by `bankUpiConfirm()`. Uses cached Cashfree payload from Step 5.3.

| Body field             | Required                                            | Notes |
| ---------------------- | --------------------------------------------------- | ----- |
| `upi_id`             | Yes — must match the lookup VPA                    |       |
| `bank_name`          | No — falls back to Cashfree data                   |       |
| `account_type`       | No — default `"SB"`                              |       |
| `investor_residency` | No —`"Resident"` / `"NRI-NRE"` / `"NRI-NRO"` |       |

**200**

```json
{
  "success": true,
  "data": {
    "bank": { "bank_name": "AXIS BANK", "account_number": "...", "ifsc_code": "...", "is_default": true },
    "next_step": "profile",
    "onboarding_status": "PROFILE"
  }
}
```

**400** — cache miss (lookup not done or expired), VPA mismatch.

---

### 5.5 `POST /api/v2/profile/bank/manual/`

Save bank account by manual entry (account number + IFSC). Calls Cashfree bank-account sync unless `skip_verification: true`. Called by `bankManualSave()`.

| Body field             | Required                             | Notes |
| ---------------------- | ------------------------------------ | ----- |
| `account_number`     | Yes                                  |       |
| `ifsc_code`          | Yes — 11-char                       |       |
| `bank_name`          | No — fetched from IFSC DB if absent |       |
| `account_type`       | No — default `"SB"`               |       |
| `upi_id`             | No                                   |       |
| `skip_verification`  | No — default `false`              |       |
| `investor_residency` | No                                   |       |

**200**

```json
{
  "success": true,
  "data": {
    "bank": { ... },
    "next_step": "profile",
    "name_at_bank": "JOHN DOE",
    "onboarding_status": "PROFILE"
  }
}
```

**400** — invalid IFSC, Cashfree failure, account mismatch.

---

## 6. Investor residency (apiv2)

### 6.1 `GET /api/v2/profile/residency/`

Called by `getResidency()` in `ordersApi.js`.

**200**

```json
{
  "success": true,
  "data": {
    "investor_residency": "Resident",
    "options": [
      { "value": "Resident", "label": "Resident Individual (RI)" },
      { "value": "NRI-NRE",  "label": "NRI — NRE account" },
      { "value": "NRI-NRO",  "label": "NRI — NRO account" }
    ]
  }
}
```

---

### 6.2 `POST /api/v2/profile/residency/`

Set / change residency type. Called by `setResidency()`.

| Body field                              | Required | Notes                                                                                              |
| --------------------------------------- | -------- | -------------------------------------------------------------------------------------------------- |
| `investor_residency` or `residency` | Yes      | Accepts aliases:`"RI"` → `"Resident"`, `"NRE"` → `"NRI-NRE"`, `"NRO"` → `"NRI-NRO"` |

**200** → `{ "success": true, "data": { "investor_residency": "Resident" } }`
**400** — unrecognised value.

---

## 7. Profile details & update (apiv2)

### 7.1 `GET /api/v2/profile/details/`

Full user profile read. Called by `fetchProfileDetails()` in `profileUpdateApi.js` and in `MfInvestOrderWizard` on open to prefill UPI ID.

**200**

```json
{
  "success": true,
  "onboarding_status": "COMPLETE",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "phone_number": "+919876543210",
    "pan_number": "ABCDE1234F",
    "first_name": "John",
    "last_name": "Doe",
    "dob": "1990-01-01",
    "gender": "M",
    "occupation": "...",
    "onboarding_status": "COMPLETE",
    "profile_issues": [],
    "identity_verified": true,
    "profile_complete": true,
    "profile_requirements": {
      "contact": true,
      "pan": true,
      "bank": true,
      "address": true,
      "details": true
    },
    "validate": true,
    "holders": [
      {
        "id": 1,
        "name": "Jane Doe",
        "pan_number": "FGHIJ5678K",
        "dob": "1992-05-15",
        "email": "jane@example.com",
        "phone_number": "+919876543211",
        "gender": "F",
        "relationship_to_primary": "SPOUSE",
        "is_verified": true,
        "has_signature": true,
        "signature": "<base64 PNG or null>"
      }
    ],
    "payment_upi_id": "john@okaxis",
    "default_bank": {
      "bank_name": "AXIS BANK",
      "account_number": "••••1234",
      "ifsc_code": "UTIB0000001",
      "upi_id": "john@okaxis"
    },
    "ucc_profile": { "upi_id": "john@okaxis" },
    "address_info": {
      "pan_address": { "address1": "...", "city": "...", "state": "...", "pincode": "..." },
      "correspondence_address": { "..." : "..." },
      "indian_address": null,
      "residency": "Resident",
      "is_nri": false,
      "needs_indian_address": false,
      "needs_overseas_address": false,
      "guidance": {}
    }
  }
}
```

**Key usage in wizard:** `data.payment_upi_id` or `data.default_bank.upi_id` or `data.ucc_profile.upi_id` is extracted to prefill the UPI field on the payment step.

---

### 7.2 `PATCH /api/v2/profile/update/`

Update profile fields. Called by `updateProfile()`.

| Body field             | Required | Notes                            |
| ---------------------- | -------- | -------------------------------- |
| `investor_residency` | No       |                                  |
| `extended_profile`   | No       | Dict with UCC-level fields below |
| `phone_number`       | No       | Direct `User` field            |
| `dob`                | No       |                                  |
| `pan_number`         | No       |                                  |

**`extended_profile` keys:**

| Key                                                                      | Notes                       |
| ------------------------------------------------------------------------ | --------------------------- |
| `primary_first_name` / `primary_last_name` / `primary_middle_name` | Name fields                 |
| `dob`                                                                  | `"YYYY-MM-DD"`            |
| `gender`                                                               | `"M"` / `"F"` / `"O"` |
| `occupation`                                                           | Occupation code             |
| `country`                                                              | Default `"IND"`           |
| `address_line_1` / `address_line_2`                                  | Correspondence address      |
| `city` / `state` / `pincode`                                       |                             |
| `ind_address_line_1` etc.                                              | Indian address for NRI only |

**200** — re-serialized user (same shape as `GET /profile/details/`).
**400 / 401** — validation or beta service error; see `message` + `data.beta`.

---

## 8. Joint holders (apiv2)

Holders are people (other than the primary user) stored in `UserHolder`. They can be used as:

- Second holders on a joint (`AS`) UCC
- Nominees for a UCC

Source: `apiv2/views/holders.py`. Called by `profileUpdateApi.js`.

### 8.1 `GET /api/v2/profile/holders/`

List all holders on file. Called by `fetchHolders()` — used in the wizard step 1 (second-holder dropdown) and step 2 (nominee dropdown).

**200**

```json
{
  "success": true,
  "data": {
    "holders": [
      {
        "id": 1,
        "name": "Jane Doe",
        "pan_number": "FGHIJ5678K",
        "dob": "1992-05-15",
        "email": "jane@example.com",
        "phone_number": "+919876543211",
        "gender": "F",
        "relationship_to_primary": "SPOUSE",
        "father_name": "...",
        "investor_residency": "Resident",
        "tin": null,
        "is_verified": true,
        "has_signature": true,
        "kyc_status": "VALID",
        "address": { "..." : "..." },
        "signature": "<base64 PNG or null>"
      }
    ],
    "count": 1
  }
}
```

---

### 8.2 `POST /api/v2/profile/holders/`

Create a holder by PAN. Backend calls Cashfree PAN360 to fetch name + DOB. Called by `createHolderFromPan()`.

| Body field     | Required | Notes       |
| -------------- | -------- | ----------- |
| `pan_number` | Yes      | 10-char PAN |

**200**

```json
{
  "success": true,
  "message": "PAN verified. Holder details fetched from bureau.",
  "data": {
    "holder": { ... },
    "self": false
  }
}
```

`data.self: true` means the PAN belongs to the primary user (not a valid second holder — show error).
**400** — invalid PAN format, bureau failure.
**409** — holder with this PAN already exists on this account.

---

### 8.3 `GET /api/v2/profile/holders/{pk}/`

Fetch a single holder's details. Called by `fetchHolderDetail()`.

**200** → `{ "success": true, "data": { "holder": { ... } } }`
**404** — not found or not owned by the user.

---

### 8.4 `PATCH /api/v2/profile/holders/{pk}/`

Update holder fields. Called by `updateHolder()`. Used to add DOB, signature, relationship before using as a nominee (BSE requires all these).

| Body field                  | Required | Notes                                                                                                                                                      |
| --------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                    | No       | Full name                                                                                                                                                  |
| `email`                   | No       |                                                                                                                                                            |
| `phone_number`            | No       |                                                                                                                                                            |
| `dob`                     | No*      | `"YYYY-MM-DD"` — **required** for nominees (BSE mandate)                                                                                          |
| `tin`                     | No       | Tax Identification Number — required for NRI holders                                                                                                      |
| `investor_residency`      | No       | `"Resident"` / `"NRI-NRE"` / `"NRI-NRO"`                                                                                                             |
| `gender`                  | No       | `"M"` / `"F"` / `"O"`                                                                                                                                |
| `father_name`             | No       |                                                                                                                                                            |
| `relationship_to_primary` | No*      | **Required** for nominees. BSE codes 1–8 or labels: `"SPOUSE"`, `"FATHER"`, `"MOTHER"`, `"SON"`, `"DAUGHTER"`, `"SIBLING"`, `"OTHER"` |
| `address`                 | No       | Dict:`address_line_1`, `address_line_2`, `city`, `state`, `pincode`, `country`                                                                 |
| `signature`               | No*      | Base64-encoded PNG —**required** for second holders on an `AS` UCC; min 80 chars                                                                  |

**200** → updated holder.
**400** — validation failure.

---

### 8.5 `DELETE /api/v2/profile/holders/{pk}/`

Remove a holder. Called by `deleteHolder()`.

**204** — deleted.
**400** — holder is in use by an active UCC.
**404** — not found.

---

## 9. Fund discovery — browse & filters (apiv2)

### 9.1 `GET /api/v2/mutual-funds/browse-public/`

No auth. Used for the pre-login fund catalog. Called by `fetchMutualFundsBrowsePublic()`.

| Query param        | Required | Notes                                                            |
| ------------------ | -------- | ---------------------------------------------------------------- |
| `start`          | No       | Default `0` (offset)                                           |
| `length`         | No       | Default `30`, max `30`                                       |
| `q` or `query` | No       | Min 2 chars; searches name, ISIN, AMC                            |
| `include_total`  | No       | `"1"` to get `total_count` (extra DB query)                  |
| `plan_type`      | No       | `"direct"` or `"regular"`                                    |
| `category`       | No       | Min 2 chars partial match, e.g.`"Equity"`                      |
| `sub_category`   | No       | Min 2 chars                                                      |
| `amc`            | No       | Min 2 chars partial match on AMC name                            |
| `scheme_option`  | No       | Exact:`"Growth"` / `"IDCW Payout"` / `"IDCW Reinvestment"` |
| `budget`         | No       | Positive integer ₹ — filters min lumpsum ≤ this value         |

> POST is also accepted with same keys in body.

**200**

```json
{
  "success": true,
  "data": {
    "start": 0,
    "length": 30,
    "has_more": true,
    "total_count": 250,
    "q": "hdfc",
    "plan_type_filter": "direct",
    "category_filter": "Equity",
    "sub_category_filter": null,
    "amc_filter": null,
    "scheme_option_filter": null,
    "budget_filter": 10000,
    "investor_category": "SI",
    "investor_residency": null,
    "browse_context": "resident_india_guest",
    "schemes": [
      {
        "scheme_isin": "INF179K01AA4",
        "name": "HDFC Flexi Cap Fund - Direct Plan - Growth",
        "scheme_code": "HDFC_FCP_DP_G",
        "minimum_amount": 100.0,
        "current_nav": 120.45,
        "latest_nav_date": "2026-04-23",
        "plan_type": "Direct",
        "amc_name": "HDFC Mutual Fund",
        "category": "Equity",
        "sub_category": "Flexi Cap Fund",
        "scheme_option": "Growth"
      }
    ]
  }
}
```

---

### 9.2 `GET /api/v2/mutual-funds/browse/`

Auth required. Same query params as §9.1. Eligibility filtered by user's residency + AMC NRI whitelist. Called by `fetchMutualFundsBrowse()`.

**403 — PAN not verified**

```json
{ "success": false, "message": "Complete PAN verification before browsing.", "data": { "next_step": "pan" } }
```

---

### 9.3 `GET /api/v2/mutual-funds/browse/filter-options/`

No auth. Returns all distinct filter values for the browse UI. Called by `fetchMutualFundsBrowseFilterOptions()`.

**200**

```json
{
  "success": true,
  "data": {
    "categories": ["Equity", "Debt", "Hybrid", "Solution Oriented", "Other"],
    "sub_categories": ["Large Cap Fund", "Mid Cap Fund", "..."],
    "scheme_options": ["Growth", "IDCW Payout", "IDCW Reinvestment"],
    "plan_types": ["Direct", "Regular"],
    "amcs": ["HDFC Mutual Fund", "ICICI Prudential", "..."]
  }
}
```

---

## 10. Fund detail (apiv2)

### `GET /api/v2/mutual-funds/detail/?isin=INF…`

Auth + PAN verified. Full scheme data — BSE rules, NAV history, VR analytics. Called by `fetchMutualFundDetail()`.

| Query / body                | Required | Notes            |
| --------------------------- | -------- | ---------------- |
| `isin` or `scheme_isin` | Yes      | Case-insensitive |

**200**

```json
{
  "success": true,
  "data": {
    "investor_category": "SI",
    "validation_summary": {
      "is_investable": true,
      "is_lumpsum_allowed": true,
      "is_sip_allowed": true,
      "is_lumpsum_ok": true,
      "is_sip_ok": true,
      "amount_validation": {
        "lumpsum": { "min_amount": 500, "max_amount": null, "multiple": 1 },
        "sip":     { "min_amount": 500, "max_amount": null, "multiple": 500 }
      }
    },
    "scheme_code": "...",
    "scheme_bse_code": "...",
    "scheme_isin": "INF...",
    "name": "HDFC Flexi Cap Fund",
    "amc_name": "HDFC Mutual Fund",
    "amc_code": "HDF",
    "plan_type": "Direct",
    "category": "Equity",
    "sub_category": "Flexi Cap Fund",
    "scheme_option": "Growth",
    "current_nav": 120.45,
    "latest_nav_date": "2026-04-23",
    "nav_series": [
      { "date": "2026-01-01", "nav": 115.0 },
      { "date": "2026-04-23", "nav": 120.45 }
    ],
    "nav_source": "bse",
    "value_research": {
      "plan_id": 123,
      "returns": { "ret_1m": 1.2, "ret_3m": 3.5, "ret_1year": 14.2, "ret_3year": 18.1, "ret_5year": 22.0 },
      "latest_rating": "5 Star",
      "latest_expense_ratio": 0.52,
      "latest_aum_cr": 45000.0,
      "objective": "Long-term capital appreciation",
      "risk": "High",
      "benchmark": "Nifty 500 TRI"
    },
    "bse_summary": {
      "cutoff_time": "15:00",
      "settlement_type": "T+1",
      "amc_active_flag": true,
      "scheme_active_flag": true,
      "purchase_allowed": true,
      "redemption_allowed": true,
      "switch_in_allowed": true
    }
  }
}
```

**400** — missing ISIN, scheme not open for lumpsum/SIP, not allowed for user's residency.
**403** — PAN gate (same as browse).
**404** — scheme not found.

---

## 11. Dashboard mutual fund list (apiv2)

### `GET /api/v2/dashboard/mutual-funds/`

Auth + PAN + bank verified. Returns investable scheme list personalised for the user. Gated behind full onboarding completion.

| Query param       | Notes                             |
| ----------------- | --------------------------------- |
| `start`         | Default `0`                     |
| `length`        | Default `24`, max `200`       |
| `include_total` | Truthy to include `total_count` |

**200**

```json
{
  "success": true,
  "data": {
    "start": 0,
    "length": 24,
    "has_more": true,
    "total_count": 1800,
    "investor_category": "SI",
    "schemes": [ { "scheme_isin": "...", "name": "...", "minimum_amount": 100 } ]
  }
}
```

**403 (PAN)** → `data.next_step: "pan"`.
**403 (bank)** → `data.next_step: "bank"`.

---

## 12. Portfolio holdings (apiv2)

### 12.1 `GET /api/v2/portfolio/holdings/`

Merged view of MF Central CAS holdings + BSE purchase allotments. Called by `fetchPortfolioHoldings()`.

**200**

```json
{
  "success": true,
  "data": {
    "summary": {
      "holding_count": 5,
      "total_current_value": "100000.00",
      "total_invested": "95000.00",
      "total_pnl": "5000.00",
      "total_pnl_pct": "5.26"
    },
    "holdings": [
      {
        "mfc_holding_id": 1,
        "scheme_name": "HDFC Flexi Cap Fund - Direct Plan - Growth",
        "isin": "INF179K01AA4",
        "scheme_code": "HDFC_FCP_DP_G",
        "folio_number": "12345678",
        "amc_name": "HDFC Mutual Fund",
        "units": "10.500",
        "nav": "120.45",
        "nav_date": "2026-04-23",
        "current_value": "1264.73",
        "cost_value": "1200.00",
        "gain_loss": "64.73",
        "gain_loss_pct": "5.39",
        "sellable_units": "10.500",
        "redeem_allowed": true,
        "source": "MFC",
        "ucc_id": "c000ba4d-284f-4b3b-befb-49a0f127e477",
        "client_code": "PM_SI_4F39",
        "is_sellable": true
      }
    ],
    "uccs": [
      { "ucc_id": "c000ba4d-284f-4b3b-befb-49a0f127e477", "client_code": "PM_SI_4F39" }
    ],
    "active_sips": [
      {
        "id": 1,
        "sxp_id": "...",
        "scheme_name": "...",
        "scheme_code": "...",
        "isin": "...",
        "sip_amount": "5000.00",
        "sip_frequency": "monthly",
        "sip_start_date": "2026-02-01",
        "sip_end_date": null,
        "total_installments": 12,
        "current_installment": 3,
        "next_due_date": "2026-05-01",
        "client_code": "PM_SI_4F39",
        "status": "ACTIVE",
        "bse_status": "..."
      }
    ]
  }
}
```

`is_sellable: true` when the holding has `(scheme_code or isin)`, `ucc_id`, `sellable_units > 0`, and `redeem_allowed` is not false.

---

### 12.2 `GET /api/v2/portfolio/holdings/mfc/{pk}/`

Full MF Central holding detail. Called by `fetchMfcHoldingDetail()`.

**200**

```json
{
  "success": true,
  "data": {
    "source": "MF_CENTRAL",
    "holding": { "id": 1, "isin": "...", "units": "...", "nav_date": "...", "scheme_name": "...", ... },
    "folio": { "id": 1, "folio_number": "12345678", "amc_name": "...", "pan": "..." }
  }
}
```

**404** — not found or wrong user.

---

## 13. Order history & detail (apiv2)

### 13.1 `GET /api/v2/orders/?side=buy|sell|switch|sip`

All orders for the user. Called by `fetchOrders()`.

| Query param | Notes                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------ |
| `side`    | `buy` / `sell` / `switch` / `sip` — filter. Omit = all. Max 500 rows per section. |

**200**

```json
{
  "success": true,
  "data": {
    "buy_orders": [
      {
        "id": 1,
        "record_type": "mutual_fund",
        "side": "Buy",
        "type_code": "P",
        "status": "PLACED",
        "ui_status": "Payment Pending",
        "bse_order_id": "2026041200001",
        "bse_order_status": "...",
        "bse_remark": "",
        "amount": "5000.00",
        "scheme": { "id": 1, "name": "HDFC Flexi Cap Fund", "isin": "INF...", "amc": "HDFC Mutual Fund" },
        "client_code": "PM_SI_4F39",
        "folio_number": "12345678",
        "placed_at": "2026-04-23T10:30:00+05:30",
        "payment_ref_no": "...",
        "allotment_date": null,
        "allotment_units": null,
        "allotment_price": null,
        "created_at": "2026-04-23T10:30:00+05:30",
        "updated_at": "2026-04-23T10:35:00+05:30"
      }
    ],
    "sell_orders": [],
    "switch_orders": [],
    "sip_orders": [
      {
        "id": 1,
        "record_type": "sip",
        "sxp_id": "...",
        "status": "ACTIVE",
        "bse_status": "...",
        "sip_amount": "5000.00",
        "sip_frequency": "monthly",
        "sip_start_date": "2026-02-01",
        "sip_end_date": null,
        "total_installments": 12,
        "current_installment": 3,
        "scheme": { "id": 1, "name": "...", "isin": "...", "amc": "..." },
        "client_code": "PM_SI_4F39",
        "next_due_date": "2026-05-01",
        "created_at": "...",
        "updated_at": "..."
      }
    ],
    "counts": { "buy": 1, "sell": 0, "switch": 0, "sip": 1 }
  }
}
```

---

### 13.2 `GET /api/v2/orders/mutual-fund/{pk}/`

Full buy/sell/switch order detail including investor UCC, nominees, banks, BSE payloads. Called by `fetchMutualFundOrderDetail()`.

**200** → `{ "success": true, "data": { "order": { ...all fields from §13.1 + "phys_or_demat", "is_fresh", "mem_ord_ref_id", "payment": { ... }, "investor": { full UCC + holders + nominees + banks }, "scheme_full": { "scheme_code", "amc_name", ... } } } }`
**404** — not found.

---

### 13.3 `GET /api/v2/orders/sip/{pk}/`

Full SIP detail including installments history. Called by `fetchSipOrderDetail()`.

**200** → `{ "success": true, "data": { "sip": { ...all fields from §13.1 + "mandate_id", "mandate_status", "installments": [...], "investor": { ... }, "request_payload", "response_payload" } } }`
**404** — not found.

---

## 14. UCC trade wizard — full flow (apiv2)

> A **UCC (Universal Client Code)** is the BSE-registered identity that enables trading. Every user needs one before placing any order. The wizard creates it.

### 14.1 `POST /api/v2/trade/ucc/resolve/`

**When called:** After user picks holding nature + nominee (wizard step 2). Checks if a matching UCC already exists on BSE before creating a draft. Called by `tradeUccResolve()`.

| Body field              | Required       | Notes                                                 |
| ----------------------- | -------------- | ----------------------------------------------------- |
| `holding_nature`      | No             | Default `"SI"`. `"SI"` = single, `"AS"` = joint |
| `secondary_holder_id` | If `AS`      | `UserHolder` pk of the second holder                |
| `nomination`          | No             | `"provide"` or `"skip"`                           |
| `nominee_holder_id`   | If `provide` | `UserHolder` pk                                     |

**200 — UCC already active on BSE**

```json
{
  "success": true,
  "data": {
    "exists": true,
    "ucc_id": "c000ba4d-284f-4b3b-befb-49a0f127e477",
    "client_code": "PM_SI_4F39",
    "investment_ready": true,
    "beta_stage": "bse_wizard_complete",
    "payment_upi_id": "user@okaxis"
  }
}
```

**200 — UCC syncing (BSE processing)**

```json
{
  "success": true,
  "data": {
    "exists": true,
    "ucc_id": "...",
    "client_code": "PM_SI_4F39",
    "investment_ready": false,
    "ucc_sync_pending": true,
    "beta_stage": "ready_for_bse_verify",
    "payment_upi_id": "..."
  }
}
```

**200 — No existing UCC, must create**

```json
{
  "success": true,
  "data": {
    "exists": false,
    "holding_nature": "SI",
    "payment_upi_id": "user@okaxis"
  }
}
```

**`beta_stage` values and wizard meaning:**

| `beta_stage`           | Wizard action                                          |
| ------------------------ | ------------------------------------------------------ |
| `awaiting_nomination`  | Call `/nomination/` with current choice              |
| `awaiting_optout_otp`  | Call `/nominee-opt-out/resend/` then show OTP screen |
| `ready_for_bse_verify` | Backend auto-submits; go to amount step                |
| `bse_wizard_complete`  | UCC done; go to amount step                            |

---

### 14.2 `POST /api/v2/trade/ucc/lookup/`

Lighter UCC existence check (no BSE network call). Called by `tradeUccLookup()`.

| Body field              | Required      | Notes                                                         |
| ----------------------- | ------------- | ------------------------------------------------------------- |
| `holding_nature`      | No            | Default `"AS"` in code — pass `"SI"` explicitly for solo |
| `secondary_holder_id` | Yes if `AS` |                                                               |

**200** → same shape as resolve: `exists`, `ucc_id?`, `client_code?`, `investment_ready`, `holding_nature`, `payment_upi_id`.

---

### 14.3 `POST /api/v2/trade/ucc/draft/`

Create or reuse a UCC draft. Called by `tradeUccDraft()` when resolve returns `exists: false`.

| Body field              | Required      | Notes                |
| ----------------------- | ------------- | -------------------- |
| `holding_nature`      | Yes           | `"SI"` or `"AS"` |
| `secondary_holder_id` | Yes if `AS` |                      |

**200**

```json
{
  "success": true,
  "data": {
    "reused": false,
    "client_code": "PM_SI_4F39",
    "ucc_id": null,
    "investment_ready": false,
    "beta_stage": "awaiting_nomination",
    "payment_upi_id": "user@okaxis"
  }
}
```

**400 — profile gaps**

```json
{
  "success": false,
  "message": "Profile incomplete — check primary & holder profiles.",
  "data": { "gaps": ["dob", "gender", "address"] }
}
```

---

### 14.4 `POST /api/v2/trade/ucc/nomination/`

Set nomination for a UCC draft. Called by `tradeUccNomination()`.

| Body field            | Required           | Notes                            |
| --------------------- | ------------------ | -------------------------------- |
| `client_code`       | Yes                | BSE client code of the draft UCC |
| `choice`            | Yes                | `"provide"` or `"skip"`      |
| `nominee_holder_id` | Yes if `provide` | Must have DOB + relationship set |

**200 — provide path (backend auto-submits to BSE)**

```json
{
  "success": true,
  "data": {
    "client_code": "PM_SI_4F39",
    "ucc_id": "c000ba4d-...",
    "bse_finished": true,
    "next_action": "bse_finished",
    "payment_upi_id": "user@okaxis"
  }
}
```

**200 — skip path (OTP required)**

```json
{
  "success": true,
  "data": {
    "client_code": "PM_SI_4F39",
    "next_action": "optout_otp",
    "delivery": { "email_sent": true, "email_masked": "j***@example.com" },
    "debug_opt_out_otp": "123456"
  }
}
```

`debug_opt_out_otp` appears **only in DEBUG mode** — never show in production.

---

### 14.5 `POST /api/v2/trade/ucc/nominee-opt-out/verify/`

Verify the nomination opt-out email OTP. Called by `tradeUccNomineeOptOutVerify()`.

| Body field      | Required |
| --------------- | -------- |
| `client_code` | Yes      |
| `otp`         | Yes      |

**200**

```json
{
  "success": true,
  "data": {
    "client_code": "PM_SI_4F39",
    "ucc_id": "c000ba4d-...",
    "bse_finished": true,
    "next_action": "bse_finished",
    "payment_upi_id": "user@okaxis"
  }
}
```

**400** — wrong OTP; `data.details.error` has BSE error text.

---

### 14.6 `POST /api/v2/trade/ucc/nominee-opt-out/resend/`

Resend the opt-out OTP. Called by `tradeUccNomineeOptOutResend()`.

| Body field      | Required |
| --------------- | -------- |
| `client_code` | Yes      |

**200** → `{ "success": true, "data": { "delivery": { "email_sent": true, "email_masked": "..." }, "debug_opt_out_otp": "..." } }`
**400** — UCC not in `awaiting_optout_otp` stage.

---

### 14.7 `POST /api/v2/trade/ucc/bse/finish/`

Submit BSE AOF OTP (email code from BSE) to complete UCC onboarding. Called by `tradeUccBseFinish()`.

| Body field      | Required                      |
| --------------- | ----------------------------- |
| `client_code` | Yes                           |
| `otp`         | Yes — email code sent by BSE |

**200** → `{ "success": true, "data": { "ucc_id": "...", "client_code": "...", "payment_upi_id": "..." } }`
**400** — wrong OTP, BSE rejection.

---

### 14.8 `GET /api/v2/trade/ucc/status/`

Poll UCC wizard state. Called by `tradeUccStatus()`.

| Query param     | Required | Notes                               |
| --------------- | -------- | ----------------------------------- |
| `client_code` | Yes      | BSE client code of the UCC to check |

**200**

```json
{
  "success": true,
  "data": {
    "client_code": "PM_SI_4F39",
    "ucc_id": "...",
    "stage": "bse_wizard_complete",
    "ready_for_bse_confirmation": false,
    "bse_wizard": { "s1": true, "s2": true, "s3": true },
    "nomination_choice": "skip",
    "bse_status": "APPROVED",
    "investment_ready": true,
    "payment_upi_id": "user@okaxis"
  }
}
```

---

### 14.9 `POST /api/v2/trade/setup/`

One-shot alternative to resolve → draft → nomination chain. Preferred when building a simpler onboarding. Called by `tradeSetup()` (used in `TradeSetupAPIView`).

| Body field              | Required           | Notes                       |
| ----------------------- | ------------------ | --------------------------- |
| `holding_nature`      | No                 | Default `"SI"`            |
| `secondary_holder_id` | Yes if `AS`      |                             |
| `nomination_choice`   | Yes                | `"provide"` or `"skip"` |
| `nominee_holder_id`   | Yes if `provide` |                             |

**200 — `data.next_action` values:**

| `next_action`              | UX meaning                                             |
| ---------------------------- | ------------------------------------------------------ |
| `ready`                    | UCC is investment-ready — proceed to amount / mandate |
| `opt_out_otp`              | Skip path — call `verify-optout` with email OTP     |
| `pending_bse_verification` | BSE processing asynchronously — show wait state       |

**400** → `data.gaps` lists missing profile fields.

---

### 14.10 `POST /api/v2/trade/setup/verify-optout/`

Verify opt-out OTP from the simplified setup flow. Called by `tradeSetupVerifyOptOut()`.

| Body field      | Required |
| --------------- | -------- |
| `client_code` | Yes      |
| `otp`         | Yes      |

**200** → `next_action: "ready"` (investment_ready: true) or `"pending_bse_verification"`.
**400 / 500** — invalid OTP, PDF generation error.

---

## 15. Payment poll config (apiv2)

### `GET /api/v2/trade/payment-poll-config/`

Returns BSE payment confirmation window timings. Called on wizard open and used for the countdown clock. Called by `tradePaymentPollConfig()`.

**200**

```json
{
  "success": true,
  "data": {
    "max_wait_seconds": 300,
    "poll_interval_seconds": 30
  }
}
```

---

## 16. Lumpsum buy — folio check, create order, pay (apiv1)

### Step A — `GET /api/v1/order/accounts/`

Fetch UCC accounts ready for trading. Called by `fetchOrderAccounts()` after BSE finish to refresh the accounts list.

**200**

```json
{
  "success": true,
  "data": {
    "accounts": [
      {
        "id": "c000ba4d-284f-4b3b-befb-49a0f127e477",
        "client_code": "PM_SI_4F39",
        "holding_nature": "SI",
        "is_active": true,
        "secondary_holder_name": null
      }
    ]
  }
}
```

Only returns UCCs where `is_synced_with_bse: true`, `is_investment_allowed: true`, `bse_status` in `["ACTIVE", "APPROVED"]`.

---

### Step B — `POST /api/v1/order/check_folio/{ucc_uuid}/`

Check for existing folio numbers for the same AMC on this UCC. Called by `checkExistingFolios()` when entering the wizard amount step. Always called — even on first buy.

| Path         | Required                      |
| ------------ | ----------------------------- |
| `ucc_uuid` | Yes — UCC `id` from Step A |

| Body field      | Required | Notes                        |
| --------------- | -------- | ---------------------------- |
| `scheme_code` | One of   | Preferred — BSE scheme code |
| `isin`        | One of   | Fallback                     |

**Logic:** backend finds the scheme's `scheme_amc_name`, then queries all `MutualFundOrder` rows for this UCC + any scheme from that AMC. This means if the user invested in Fund A from AMC X, that folio is offered for Fund B from AMC X too.

**200**

```json
{
  "success": true,
  "data": {
    "folios": ["12345678", "23456789"],
    "amc_name": "Aditya Birla Sun Life Mutual Fund"
  }
}
```

`folios: []` on first buy — wizard always shows "Fresh — create a new folio" (pre-selected).

---

### Step C — `POST /api/v1/order/create/`

Create the lumpsum order at BSE. Called by `createLumpsumOrder()` in `onAmountContinue()`.

| Body field       | Required    | Notes                                                                         |
| ---------------- | ----------- | ----------------------------------------------------------------------------- |
| `ucc_id`       | Yes         | UCC id (uuid string) from Step A                                              |
| `scheme_code`  | Yes         | BSE scheme_code                                                               |
| `amount`       | Yes         | Number or string in ₹                                                        |
| `mode`         | No          | Default `"Demat"`. Use `"Physical"` — wizard always sends `"Physical"` |
| `is_fresh`     | No          | Default `true`. `false` = add to existing folio                           |
| `folio_number` | Conditional | Required when `is_fresh: false` — must be a folio from Step B              |

**200**

```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "order_id": 42,
    "bse_order_id": "2026042300001",
    "amount": "5000.00",
    "bank_details": [
      { "bank_name": "AXIS BANK", "account_number": "9876543210", "ifsc_code": "UTIB0000001" }
    ],
    "upi_id": "john@okaxis"
  }
}
```

**400 — amount limits**

```json
{
  "success": false,
  "message": "Amount below minimum.",
  "details": { "limits": { "min_amount": 500, "max_amount": null, "multiple": 1 } }
}
```

`details.limits` is used by `orderCreateErrorMessage()` in the wizard to show human-readable limit info.

**400 — UCC not ready**

```json
{
  "success": false,
  "message": "UCC not yet synced with BSE.",
  "data": { "ucc_sync_pending": true }
}
```

---

### Step D — `POST /api/v1/order/payment/`

Initiate payment for a placed order. Called by `initiateOrderPayment()` in `onPayContinue()`.

| Body field       | Required    | Notes                                                  |
| ---------------- | ----------- | ------------------------------------------------------ |
| `order_id`     | Yes         | From Step C `data.order_id`                          |
| `payment_mode` | Yes         | `"UPI"` or `"NETBANKING"` (normalised server-side) |
| `upi_id`       | Conditional | VPA; required for UPI if not saved on profile          |

**200 — UPI**

```json
{
  "success": true,
  "message": "Please open your UPI app and complete the payment.",
  "data": {
    "payment_mode": "upi",
    "order_id": 42,
    "bse_payment_ref_id": "BSE_PAY_20260423_001"
  }
}
```

**200 — Netbanking**

```json
{
  "success": true,
  "data": {
    "payment_mode": "netbanking",
    "order_id": 42,
    "bse_payment_ref_id": "...",
    "payment_url": "https://bankgateway.example.com/pay?ref=...",
    "payment_method": "POST",
    "payment_params": { "ref_id": "...", "amount": "5000", "..." : "..." }
  }
}
```

When `payment_method: "POST"`, the wizard submits a hidden form via `submitNetbankingPost()` to open the bank URL in a new tab.

---

### Step E — `GET /api/v1/order/payment/status/{order_id}/`

Poll BSE for payment + allotment status. Called by `fetchOrderPaymentStatus()` every `poll_interval_seconds` (from §15).

**200**

```json
{
  "success": true,
  "data": {
    "payment_status": "AGENCY_PAYMENT_DONE",
    "order_status": "PLACED",
    "bse_order_id": "2026042300001",
    "internal_order_id": 42
  }
}
```

Wizard considers payment complete when `payment_status` contains `SUCCESS`, `COMPLETE`, or `AGENCY_PAYMENT`, or `order_status` contains `PAID`, `SUCCESS`, or `SETTLED`.

---

## 17. E-mandate + mandate-linked SIP (apiv2)

Used exclusively for SIP orders in the wizard. Mandate must be APPROVED before SIP can be registered.

### Step 1 — `GET /api/v2/trade/mandate/status/?client_code=…`

Called by `tradeMandateStatus()` in `loadMandateStatus()`. Returns mandates + bank accounts for the UCC.

| Query param     | Required | Notes                                                        |
| --------------- | -------- | ------------------------------------------------------------ |
| `client_code` | One of   | With `ucc_id`                                              |
| `ucc_id`      | One of   | InvestorUCC id                                               |
| `sip_amount`  | No       | If set, sizes `suggested_cap` and finds `usable_mandate` |

**200**

```json
{
  "success": true,
  "data": {
    "client_code": "PM_SI_4F39",
    "ucc_id": "c000ba4d-...",
    "mandates": [
      {
        "id": 1,
        "mandate_id": "BSE_MANDATE_001",
        "mandate_type": "U",
        "status": "APPROVED",
        "bse_mandate_status": "APPROVED",
        "amount_limit": 100000.0,
        "bank_acc_num": "9876543210",
        "bank_name": "AXIS BANK",
        "ifsc_code": "UTIB0000001",
        "start_date": "2026-02-01",
        "end_date": "2030-01-31",
        "mode": "DD",
        "frequency": "AS AND WHEN PRESENTED",
        "authorization_url": "https://upi-auth.npci.org.in/...",
        "authorization_sent_at": "...",
        "authorized_at": "...",
        "created_at": "...",
        "updated_at": "..."
      }
    ],
    "usable_mandate": { "...": "APPROVED mandate covering sip_amount, or null" },
    "bank_accounts": [
      {
        "id": 1,
        "account_number": "9876543210",
        "account_type": "SB",
        "ifsc_code": "UTIB0000001",
        "bank_name": "AXIS BANK",
        "bank_id": "AXIS",
        "is_default": true
      }
    ],
    "suggested_cap": 120000,
    "defaults": {
      "mandate_type": "U",
      "frequency": "AS AND WHEN PRESENTED",
      "mode": "DD"
    }
  }
}
```

Wizard logic: if any mandate is `AWAITING_AUTH` or `PENDING`, go straight to `mandate_authorize` step (skip setup). Otherwise go to `mandate_setup`.

---

### Step 2 — `POST /api/v2/trade/mandate/register/`

Register a new e-mandate with BSE and get 2FA authorisation URL. Called by `tradeMandateRegister()`.

| Body field            | Required           | Notes                                                                                 |
| --------------------- | ------------------ | ------------------------------------------------------------------------------------- |
| `client_code`       | One of             |                                                                                       |
| `ucc_id`            | One of             |                                                                                       |
| `bank_account_id`   | Yes                | Integer — must belong to the UCC                                                     |
| `max_amount`        | Yes                | Mandate cap in ₹; must be ≥ SIP amount                                              |
| `mandate_type`      | No                 | Default `"U"` (UPI Autopay). `"N"` = e-NACH (netbanking). `"X"` = NACH physical |
| `upi_id` or `vpa` | Yes for type `U` | VPA e.g.`"user@okaxis"` — sent to BSE as `investor_bank_details.vpa`             |
| `frequency`         | No                 | Default `"AS AND WHEN PRESENTED"`                                                   |
| `mode`              | No                 | Default `"DD"`                                                                      |

**200**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "mandate_id": "BSE_MANDATE_001",
    "mandate_type": "U",
    "status": "AWAITING_AUTH",
    "amount_limit": 100000.0,
    "authorization_url": "https://upi-auth.npci.org.in/...",
    "bank_name": "AXIS BANK",
    "bank_acc_num": "9876543210"
  }
}
```

Wizard opens `authorization_url` in new tab for UPI Autopay. For e-NACH (`mandate_type: "N"`), the URL is auto-opened and polled.

**400** — validation, bank not found.
**502** — BSE unreachable.
**503 / `error_code: BSE_AUTH_FAILED`** — BSE member auth failed; admin needs to refresh credentials.

---

### Step 3 — `GET /api/v2/trade/mandate/poll/?mandate_id=…`

Poll BSE for mandate authorisation status. Called every 5 seconds by `tradeMandatePoll()` in `startMandatePolling()`.

| Query param    | Required           |
| -------------- | ------------------ |
| `mandate_id` | Yes — from Step 2 |

**200** → updated mandate object (same shape as Steps 1 & 2 mandate row).

Polling stops when `status` is `APPROVED` (→ proceed to SIP create) or `REJECTED` / `EXPIRED` / `CANCELLED` (→ show error). Max poll duration: 10 minutes.

---

### Step 4 — `POST /api/v2/trade/sip/create/`

Register SIP at BSE linked to approved mandate. Called by `tradeSipCreate()` in `finishSipWithMandate()`.

| Body field                    | Required     | Notes                                                                                            |
| ----------------------------- | ------------ | ------------------------------------------------------------------------------------------------ |
| `client_code` or `ucc_id` | One required |                                                                                                  |
| `scheme_code`               | Yes          | Must exist in MutualFundScheme                                                                   |
| `amount`                    | Yes          | Per-instalment SIP amount; must be ≤ mandate `amount_limit`                                   |
| `mandate_id`                | Yes          | Must reference an APPROVED mandate for this investor                                             |
| `installments`              | No           | Default `12`                                                                                   |
| `frequency`                 | No           | Default `"monthly"` (maps to `m`); `daily`→`d`, `weekly`→`w`, `quarterly`→`q` |
| `start_date`                | No           | `"YYYY-MM-DD"`                                                                                 |
| `txn_day`                   | No           | 1–28, calendar debit day                                                                        |
| `first_order_today`         | No           | Default `true` — take first instalment payment immediately                                    |
| `is_fresh`                  | No           | Default `true` (new folio). Comes from wizard `folioChoice` state                            |
| `folio_number`              | Conditional  | Required when `is_fresh: false`                                                                |

**200**

```json
{
  "success": true,
  "data": {
    "order_id": 1,
    "bse_order_id": "...",
    "sip_reg_no": "...",
    "mandate_id": "BSE_MANDATE_001",
    "amount": 5000.0,
    "installments": 12,
    "start_date": "2026-05-01",
    "frequency": "m",
    "first_order_today": true,
    "first_payment_auto_deducted": true,
    "first_order_id": 42
  }
}
```

When `first_order_id` is present, wizard goes to payment step (step E from §16) for the first instalment. Otherwise SIP is registered with no immediate payment.

**400** — mandate not approved, amount over cap, scheme SIP not allowed, BSE error.
**404** — UCC, scheme, or mandate not found for user.

---

## 18. Legacy SIP — create / pay / status (apiv1)

> Used by `tradesApi.js` → `createSipOrder()`. **Prefer the mandate SIP in §17 for new work.** This path has no mandate — BSE collects payment per instalment.

### `POST /api/v1/sip/create/`

| Body field       | Required               | Notes                    |
| ---------------- | ---------------------- | ------------------------ |
| `ucc_id`       | Yes                    | UUID                     |
| `scheme_code`  | Yes                    |                          |
| `amount`       | Yes                    |                          |
| `mode`         | No                     | Default `"Demat"`      |
| `frequency`    | No                     | Default `"monthly"`    |
| `txn_date`     | No                     | Default `1`; day 1–28 |
| `start_date`   | No                     | `"YYYY-MM-DD"`         |
| `installments` | No                     | Default `12`           |
| `is_fresh`     | No                     | Default `true`         |
| `folio_number` | If `is_fresh: false` |                          |

**200** → same shape as lumpsum order create (§16 Step C): `order_id`, `bse_order_id`, `amount`, `bank_details[]`, `upi_id`.

### `POST /api/v1/sip/payment/`

Same body as §16 Step D (`order_id`, `payment_mode`, `upi_id`). Called by `initiateSipPayment()`.

### `GET /api/v1/sip/payment/status/{order_id}/`

Same response as §16 Step E. Called by `fetchSipPaymentStatus()`.

---

## 19. Sell / redeem (apiv1)

### `POST /api/v1/order/redeem/`

Place a sell/redemption order. Called by `redeemOrder()` in `ordersApi.js`.

| Body field                  | Required             | Notes                                     |
| --------------------------- | -------------------- | ----------------------------------------- |
| `ucc_id`                  | Yes                  | InvestorUCC id (uuid)                     |
| `scheme_code` or `isin` | One required         | Used to look up scheme                    |
| `folio_number`            | Practically required | From portfolio holdings `folio_number`  |
| `amount`                  | No                   | Redeem by ₹ amount                       |
| `units`                   | No                   | Redeem by unit count                      |
| `all_units`               | No                   | Default `false`; if `true`, full exit |
| `mode`                    | No                   | Default `"Physical"`                    |

**200**

```json
{
  "success": true,
  "message": "Redemption order placed successfully",
  "data": {
    "order_id": 43,
    "bse_order_id": "...",
    "amount": "5000.00"
  }
}
```

**400** — UCC inactive on BSE, scheme not found, BSE rejection.
**404** — UCC or scheme not found.

Track via `GET /api/v2/orders/?side=sell` (§13.1) and detail at §13.2.

---

## 20. MF Central & Finarkein account aggregator (apiv2)

### 20.1 `POST /api/v2/mf-central/initiate/`

Initiate MF Central CAS journey (hosted modal / redirect). Called by `mfCentralInitiate()`.

| Body field                  | Required     | Notes                                                           |
| --------------------------- | ------------ | --------------------------------------------------------------- |
| `pan`                     | No           | Falls back to `user.pan_number`                               |
| `email`                   | One required | If both email and mobile missing after fallback →**400** |
| `mobile`                  | One required |                                                                 |
| `from_date` / `to_date` | No           | Statement window `"YYYY-MM-DD"`                               |
| `callback_url`            | No           | Server injects default if absent                                |

**200**

```json
{
  "success": true,
  "data": {
    "redirect_url": "https://v2.bsestarmf.in/mfcentral/...",
    "client_ref_no": "MFC_20260423_001",
    "journey": { "id": 1, "client_ref_no": "...", "status": "INITIATED", "pan": "ABCDE1234F" }
  }
}
```

Open `redirect_url` in a new tab. After user completes CAS, MF Central calls back and holdings sync.
**503** — MF Central config missing.

---

### 20.2 `GET /api/v2/mf-central/status/`

Check latest MF Central journey status. Called by `mfCentralStatus()`.

**200**

```json
{
  "success": true,
  "data": {
    "has_journey": true,
    "journey": {
      "id": 1,
      "status": "COMPLETED",
      "pan": "ABCDE1234F",
      "last_synced_at": "2026-04-23T10:00:00+05:30",
      "holdings_count": 5
    }
  }
}
```

---

### 20.3 `POST /api/v2/finarkein/initiate/`

Initiate Finarkein (Account Aggregator) consent journey. Called by `finarkeinInitiate()`.

| Body field      | Required | Notes                    |
| --------------- | -------- | ------------------------ |
| `pan`         | No       | Falls back to user PAN   |
| `phone`       | No       | Falls back to user phone |
| `dob`         | No       | `"YYYY-MM-DD"`         |
| `email`       | No       |                          |
| `name`        | No       |                          |
| `redirectUrl` | No       | Post-consent redirect    |

**Response** — per FinarkeinService; includes `redirect_url` / `web_url` to open in browser.
**503** — Finarkein app not installed on server.

---

### 20.4 `POST /api/v2/finarkein/pull/`

Pull data after consent. Called by `finarkeinPullData()`.

| Body field          | Required | Notes                  |
| ------------------- | -------- | ---------------------- |
| `request_id`      | Yes      | From initiate response |
| `maxWaitSeconds`  | No       | Default 180            |
| `intervalSeconds` | No       | Default 2              |
| `skipPoll`        | No       | Default `false`      |
| `forceRefresh`    | No       | Default `false`      |

---

### 20.5 `GET /api/v2/finarkein/status/`

Check latest consent status. Called by `finarkeinStatus()`.

**200** → `{ "has_consent": true, "consent": { "status": "ACTIVE", "request_id": "...", "..." : "..." } }`

---

## 21. Health check (apiv2)

### `GET /api/v2/health/`

No auth. Used for uptime monitoring.

**200**

```json
{ "success": true, "data": { "service": "apiv2", "ok": true } }
```

---

## 22. HTTP status quick reference

| Code    | Meaning                                                                               |
| ------- | ------------------------------------------------------------------------------------- |
| `200` | Success                                                                               |
| `201` | Created (e.g. OTP sent)                                                               |
| `204` | Deleted (holder DELETE)                                                               |
| `400` | Bad request — validation error, BSE business rejection, missing field                |
| `401` | Token expired or invalid →`fetchAuthed()` auto-refreshes once, then surfaces error |
| `403` | Feature gated — check `data.next_step` for onboarding redirect                     |
| `404` | Resource not found or wrong user                                                      |
| `409` | Conflict — e.g. duplicate PAN on holder create                                       |
| `422` | Unprocessable — Cashfree UPI lookup failed                                           |
| `502` | BSE unreachable — retry later                                                        |
| `503` | Config missing (`BSE_AUTH_FAILED`) or service unavailable                           |

---

## 23. Frontend lib → endpoint matrix

All paths from `TestingFrontEnd/src/lib/http.js` → `profileV2Endpoints` and `API_PREFIX`.

| Library file            | Function                                | HTTP   | Endpoint                                        |
| ----------------------- | --------------------------------------- | ------ | ----------------------------------------------- |
| `profileApi.js`       | `getContactStatus`                    | GET    | `/api/v2/profile/contact/`                    |
| `profileApi.js`       | `sendContactOtp`                      | POST   | `/api/v2/profile/contact/otp/`                |
| `profileApi.js`       | `verifyContactOtp`                    | POST   | `/api/v2/profile/contact/otp/verify/`         |
| `profileApi.js`       | `saveContactPhone`                    | POST   | `/api/v2/profile/contact/phone/save/`         |
| `profileApi.js`       | `getPanInfo`                          | GET    | `/api/v1/profile/pan/`                        |
| `profileApi.js`       | `verifyPan`                           | POST   | `/api/v1/profile/pan_verify/`                 |
| `profileApi.js`       | `verifyPanBureau`                     | POST   | `/api/v2/profile/pan/verify/`                 |
| `profileApi.js`       | `getProfileValidate`                  | GET    | `/api/v2/profile/validate/`                   |
| `profileUpdateApi.js` | `fetchProfileDetails`                 | GET    | `/api/v2/profile/details/`                    |
| `profileUpdateApi.js` | `updateProfile`                       | PATCH  | `/api/v2/profile/update/`                     |
| `profileUpdateApi.js` | `fetchHolders`                        | GET    | `/api/v2/profile/holders/`                    |
| `profileUpdateApi.js` | `createHolderFromPan`                 | POST   | `/api/v2/profile/holders/`                    |
| `profileUpdateApi.js` | `fetchHolderDetail`                   | GET    | `/api/v2/profile/holders/{pk}/`               |
| `profileUpdateApi.js` | `updateHolder`                        | PATCH  | `/api/v2/profile/holders/{pk}/`               |
| `profileUpdateApi.js` | `deleteHolder`                        | DELETE | `/api/v2/profile/holders/{pk}/`               |
| `bankApi.js`          | `getBankState`                        | GET    | `/api/v2/profile/bank/`                       |
| `bankApi.js`          | `patchBank`                           | PATCH  | `/api/v2/profile/bank/`                       |
| `bankApi.js`          | `bankUpiLookup`                       | POST   | `/api/v2/profile/bank/upi/lookup/`            |
| `bankApi.js`          | `bankUpiConfirm`                      | POST   | `/api/v2/profile/bank/upi/confirm/`           |
| `bankApi.js`          | `bankManualSave`                      | POST   | `/api/v2/profile/bank/manual/`                |
| `ordersApi.js`        | `getResidency`                        | GET    | `/api/v2/profile/residency/`                  |
| `ordersApi.js`        | `setResidency`                        | POST   | `/api/v2/profile/residency/`                  |
| `ordersApi.js`        | `fetchOrders`                         | GET    | `/api/v2/orders/`                             |
| `ordersApi.js`        | `fetchPortfolioHoldings`              | GET    | `/api/v2/portfolio/holdings/`                 |
| `ordersApi.js`        | `fetchMutualFundOrderDetail`          | GET    | `/api/v2/orders/mutual-fund/{pk}/`            |
| `ordersApi.js`        | `fetchSipOrderDetail`                 | GET    | `/api/v2/orders/sip/{pk}/`                    |
| `ordersApi.js`        | `fetchMfcHoldingDetail`               | GET    | `/api/v2/portfolio/holdings/mfc/{pk}/`        |
| `ordersApi.js`        | `redeemOrder`                         | POST   | `/api/v1/order/redeem/`                       |
| `mfBrowseApi.js`      | `fetchMutualFundsBrowsePublic`        | GET    | `/api/v2/mutual-funds/browse-public/`         |
| `mfBrowseApi.js`      | `fetchMutualFundsBrowseFilterOptions` | GET    | `/api/v2/mutual-funds/browse/filter-options/` |
| `mfBrowseApi.js`      | `fetchMutualFundsBrowse`              | GET    | `/api/v2/mutual-funds/browse/`                |
| `mfBrowseApi.js`      | `fetchMutualFundDetail`               | GET    | `/api/v2/mutual-funds/detail/`                |
| `mfTradeApi.js`       | `tradePaymentPollConfig`              | GET    | `/api/v2/trade/payment-poll-config/`          |
| `mfTradeApi.js`       | `tradeUccResolve`                     | POST   | `/api/v2/trade/ucc/resolve/`                  |
| `mfTradeApi.js`       | `tradeUccLookup`                      | POST   | `/api/v2/trade/ucc/lookup/`                   |
| `mfTradeApi.js`       | `tradeUccDraft`                       | POST   | `/api/v2/trade/ucc/draft/`                    |
| `mfTradeApi.js`       | `tradeUccNomination`                  | POST   | `/api/v2/trade/ucc/nomination/`               |
| `mfTradeApi.js`       | `tradeUccNomineeOptOutVerify`         | POST   | `/api/v2/trade/ucc/nominee-opt-out/verify/`   |
| `mfTradeApi.js`       | `tradeUccNomineeOptOutResend`         | POST   | `/api/v2/trade/ucc/nominee-opt-out/resend/`   |
| `mfTradeApi.js`       | `tradeUccBseFinish`                   | POST   | `/api/v2/trade/ucc/bse/finish/`               |
| `mfTradeApi.js`       | `tradeUccStatus`                      | GET    | `/api/v2/trade/ucc/status/`                   |
| `mandateApi.js`       | `tradeMandateStatus`                  | GET    | `/api/v2/trade/mandate/status/`               |
| `mandateApi.js`       | `tradeMandateRegister`                | POST   | `/api/v2/trade/mandate/register/`             |
| `mandateApi.js`       | `tradeMandatePoll`                    | GET    | `/api/v2/trade/mandate/poll/`                 |
| `mandateApi.js`       | `tradeSipCreate`                      | POST   | `/api/v2/trade/sip/create/`                   |
| `tradesApi.js`        | `fetchOrderAccounts`                  | GET    | `/api/v1/order/accounts/`                     |
| `tradesApi.js`        | `checkExistingFolios`                 | POST   | `/api/v1/order/check_folio/{ucc_id}/`         |
| `tradesApi.js`        | `createLumpsumOrder`                  | POST   | `/api/v1/order/create/`                       |
| `tradesApi.js`        | `createSipOrder`                      | POST   | `/api/v1/sip/create/`                         |
| `tradesApi.js`        | `initiateOrderPayment`                | POST   | `/api/v1/order/payment/`                      |
| `tradesApi.js`        | `fetchOrderPaymentStatus`             | GET    | `/api/v1/order/payment/status/{id}/`          |
| `tradesApi.js`        | `initiateSipPayment`                  | POST   | `/api/v1/sip/payment/`                        |
| `tradesApi.js`        | `fetchSipPaymentStatus`               | GET    | `/api/v1/sip/payment/status/{id}/`            |
| `aggregatorsApi.js`   | `mfCentralInitiate`                   | POST   | `/api/v2/mf-central/initiate/`                |
| `aggregatorsApi.js`   | `mfCentralStatus`                     | GET    | `/api/v2/mf-central/status/`                  |
| `aggregatorsApi.js`   | `finarkeinInitiate`                   | POST   | `/api/v2/finarkein/initiate/`                 |
| `aggregatorsApi.js`   | `finarkeinPullData`                   | POST   | `/api/v2/finarkein/pull/`                     |
| `aggregatorsApi.js`   | `finarkeinStatus`                     | GET    | `/api/v2/finarkein/status/`                   |

---

## 24. MfInvestOrderWizard step-by-step API flow

`MfInvestOrderWizard.jsx` is the main trade entry point. Here is every API call it makes, in order, for both BUY (lumpsum) and SIP paths.

### On wizard open (parallel)

| Call                         | Purpose                                                                    |
| ---------------------------- | -------------------------------------------------------------------------- |
| `fetchHolders()`           | Populate second-holder dropdown (Step 1) and nominee dropdown (Step 2)     |
| `fetchProfileDetails()`    | Prefill `upiId` state from `payment_upi_id` / `default_bank.upi_id`  |
| `tradePaymentPollConfig()` | Fetch `max_wait_seconds` + `poll_interval_seconds` for countdown clock |

---

### Step 1 — Secondary holder (no API call)

User picks: single holder (SI) or joint second holder (AS). No API call on continue.

---

### Step 2 — Nomination (multiple API calls on continue)

`onNomineeContinue()` always starts with:

**Call 1 — `tradeUccResolve()`** → `POST /api/v2/trade/ucc/resolve/`

Decision tree on response:

| Condition                                           | Next call                                     |
| --------------------------------------------------- | --------------------------------------------- |
| `exists && investment_ready && ucc_id`            | → set `uccId`, go to **amount** step |
| `exists && ucc_sync_pending`                      | → show error, stop                           |
| `exists && beta_stage === "awaiting_nomination"`  | Call `tradeUccNomination()`                 |
| `exists && beta_stage === "awaiting_optout_otp"`  | Call `tradeUccNomineeOptOutResend()`        |
| `exists && beta_stage === "bse_wizard_complete"`  | → go to**amount** step                 |
| `exists && beta_stage === "ready_for_bse_verify"` | → go to**amount** step                 |
| `!exists`                                         | → Call `tradeUccDraft()`                   |

**If nomination needed:** `tradeUccNomination()` → `POST /api/v2/trade/ucc/nomination/`

- `bse_finished: true` → go to **amount** step (calls `fetchOrderAccounts()` to refresh sidebar)
- Otherwise → go to `bse_otp` step

**If draft needed:** `tradeUccDraft()` → `POST /api/v2/trade/ucc/draft/`

- Then same nomination logic as above

---

### Step 3a — Opt-out OTP (skip nomination path)

`onOptOutVerify()` → `tradeUccNomineeOptOutVerify()` → `POST /api/v2/trade/ucc/nominee-opt-out/verify/`

- `bse_finished: true` → go to **amount** step
- Otherwise → go to `bse_otp` step

`onOptOutResend()` → `tradeUccNomineeOptOutResend()` → `POST /api/v2/trade/ucc/nominee-opt-out/resend/`

---

### Step 3b — BSE OTP (provide-nominee path)

`onBseFinish()` → `tradeUccBseFinish()` → `POST /api/v2/trade/ucc/bse/finish/`

- On success → calls `fetchOrderAccounts()` → go to **amount** step

---

### Amount step — on enter

**`checkExistingFolios(uccId, schemeCode)`** → `POST /api/v1/order/check_folio/{uccId}/`

- Sets `existingFolios` state (empty array = first buy, array with values = existing AMC folios)
- Button stays disabled until this resolves
- Dropdown always shown: "Fresh — create a new folio" (pre-selected) + any existing folios

**`folioChoice` state:**

- `"__fresh__"` (default) → order sent with `is_fresh: true`
- `"<folio_number>"` (e.g. `"12345678"`) → order sent with `is_fresh: false, folio_number: "12345678"`

---

### Amount step — on continue (BUY path)

**`createLumpsumOrder()`** → `POST /api/v1/order/create/`

- On success: `setOrderId(data.order_id)` → go to **payment** step

---

### Amount step — on continue (SIP path)

**`tradeMandateStatus()`** → `GET /api/v2/trade/mandate/status/?client_code=…`

- Pending mandate exists → go to `mandate_authorize` step
- No mandate → go to `mandate_setup` step

---

### Mandate setup step

**`tradeMandateRegister()`** → `POST /api/v2/trade/mandate/register/`

- On success: set `activeMandate` → go to `mandate_authorize` step

---

### Mandate authorize step (polling every 5s, max 10 min)

**`tradeMandatePoll()`** → `GET /api/v2/trade/mandate/poll/?mandate_id=…`

- `APPROVED` → calls `tradeSipCreate()` → `POST /api/v2/trade/sip/create/`
  - `first_order_id` present → go to **payment** step
  - No `first_order_id` → SIP registered, close wizard

---

### Payment step (on "Start payment")

If entering payment step with `payMode === "upi"`:

- **`fetchProfileDetails()`** → `GET /api/v2/profile/details/` (refresh UPI ID from DB)

**`initiateOrderPayment()`** → `POST /api/v1/order/payment/`*(or `initiateSipPayment()` → `POST /api/v1/sip/payment/` for legacy SIP)*

- UPI → go to **polling** step
- Netbanking (GET) → open `payment_url` in new tab → go to **polling** step
- Netbanking (POST) → `submitNetbankingPost()` hidden form → go to **polling** step

---

### Polling step (every `poll_interval_seconds`, max `max_wait_seconds`)

**`fetchOrderPaymentStatus(orderId)`** → `GET /api/v1/order/payment/status/{orderId}/`
*(or `fetchSipPaymentStatus()` for non-mandate SIP)*

Payment considered complete when:

- `payment_status` contains `SUCCESS`, `COMPLETE`, or `AGENCY_PAYMENT`
- OR `order_status` contains `PAID`, `SUCCESS`, or `SETTLED`

On complete → go to **success** step, close wizard.
On timeout → back to **payment** step with error message.

---

## 25. Theory: when to call which API (onboarding, UCC, invest)

Think of the product in **layers**. Each layer uses different APIs; they are **not** interchangeable.

### 25.1 Layer A — Session (unauthenticated)

- **`POST /api/v1/auth/login/`** — send OTP; the live `LoginAPIView` expects **`identifier`** in the JSON body (email or phone in one string). (Some older doc snippets may say `phone_number` / `email` separately; align the client with the branch you deploy.)
- **`POST /api/v1/auth/verify/`** — exchange OTP for **access** + **refresh** JWT.
- **`POST /api/v1/auth/refresh/`** — new access token; `fetchAuthed` helpers in `TestingFrontEnd` use this on `401`.

No UCC and no profile gate here — only identity + tokens.

### 25.2 Layer B — KYC / profile onboarding (authenticated, before “ready to open UCC”)

Drive screens from **`GET /api/v2/profile/validate/`** (state machine: `next_step`, `context`, per-section `status`).

Typical chain (order varies by user): contact, PAN, address, bank, details, optional MF Central and Finarkein — see [`onboarding_new.md`](onboarding_new.md) in this folder for the full contract.

**When `next_step` is `"complete"`** in validate: the user has satisfied the **onboarding gate** for profile. That does **not** by itself create a BSE UCC; it means the backend is happy with the profile shape **before** **UCC draft** creation (when the user goes to invest).

**Supporting endpoints** (see sections 2–8 in this file): e.g. profile details, update, contact OTP, bank UPI, holders.

### 25.3 Layer C — UCC creation (authenticated, at invest time or a dedicated UCC flow)

A **UCC** is a `InvestorUCC` row plus BSE onboarding. Create it with the **§14** trade APIs. Two product patterns:

| Pattern | APIs | In this repo |
|--------|------|--------------|
| **Multi-step** (resolve → draft → nomination → OTPs) | `POST /api/v2/trade/ucc/resolve/`, then as needed `.../draft/`, `.../nomination/`, opt-out verify or resend, `.../bse/finish/`, optional `.../status/` | **`TestingFrontEnd` `MfInvestOrderWizard`** (§24) |
| **One-shot** | `POST /api/v2/trade/setup/` and optionally `.../setup/verify-optout/` | Documented in **§14.9–14.10**; **not** used by `TestingFrontEnd` (see **§27**) |

One invest-wizard run targets **one** UCC (either **reuse** from resolve or **create** one draft and finish it). The wizard does not bulk-create multiple UCCs in one pass.

**Identifiers after create:**

- After **`.../draft/`** the client has at least **`client_code`** for OTP steps.
- **`ucc_id`** may appear in **`.../draft/`** (reuse / ready cases) or later in **`.../nomination/`**, **`.../nominee-opt-out/verify/`**, or **`.../bse/finish/`** — see **§24** and **§26**.

### 25.4 Layer D — “Can I place an order or SIP now?” (trade-eligible UCCs)

- **`GET /api/v1/order/accounts/`** (§16 Step A) — lists UCCs that are **allowed for trading** (synced, `is_investment_allowed`, BSE `ACTIVE` / `APPROVED`).
- **Use for** account pickers for buy/SIP, **not** as a “list every draft” API.

### 25.5 Layer E — Order / payment (after a trade-ready UCC and `ucc_id`)

- **Lumpsum:** `POST /api/v1/order/check_folio/{ucc_uuid}/` → `POST /api/v1/order/create/` → `POST /api/v1/order/payment/` → poll (§16).
- **Mandate SIP (v2):** mandate register / poll / `POST /api/v2/trade/sip/create/` (§17, §24).

### 25.6 Quick checklist

| Goal | Call |
|------|------|
| Where is the user in **profile** onboarding? | `GET /api/v2/profile/validate/` |
| List UCCs **valid for trading now** | `GET /api/v1/order/accounts/` |
| Reuse or create a UCC for this holding + nomination combo | `POST /api/v2/trade/ucc/resolve/` then branch (§24) |
| New draft if resolve has no match | `POST /api/v2/trade/ucc/draft/` |
| Set provide vs skip on that draft | `POST /api/v2/trade/ucc/nomination/` |
| Place a buy | `POST /api/v1/order/create/` with `ucc_id` |

---

## 26. UCC onboarding vs order/accounts (trade-eligible list)

- **`GET /api/v1/order/accounts/`** (path: `order/accounts` — not `account/orders`, see **§28**) returns **BSE trade-eligible** UCCs only — see `OrderAccountsAPIView` in `apiv1/views/orders.py` (`is_synced_with_bse`, `is_investment_allowed`, `bse_status` in `ACTIVE` / `APPROVED`).

Implications:

- A user can hit **`next_step: complete`** on profile validate and still have **no** rows in `order/accounts` until a UCC finishes the BSE path.
- During the wizard, **`client_code`** comes from **`.../draft/`**; **`ucc_id`** is carried when the API returns it; `fetchOrderAccounts()` refreshes the account list **after** onboarding steps complete — it is not the source of in-progress drafts.

**Mobile / other clients:** to show **in-progress** UCCs you need a **separate** contract (e.g. poll `GET /api/v2/trade/ucc/status/?client_code=`) or a dedicated list API; **`order/accounts` alone** will not list drafts.

---

## 27. TestingFrontEnd vs one-shot trade/setup

- **`TestingFrontEnd`** implements the **multi-step** path (`src/lib/http.js` + `mfTradeApi.js` + `MfInvestOrderWizard.jsx`): `resolve` → `draft` → `nomination` → opt-out or BSE finish. It does **not** call **`POST /api/v2/trade/setup/`** or **`.../setup/verify-optout/`** in the current tree.
- **`POST /api/v2/trade/setup/`** (§14.9–14.10) remains a valid **server** option for a **single** combined call.

Use **§24** as the behavioural reference for the shipped test app; use **§14.9** if a new app chooses the one-shot API.

---

## 28. Common path mistakes (mobile / new clients)

| Wrong | Right |
|-------|--------|
| A URL like **`/api/v1/account/orders`** to “list UCCs” or orders | **Trade-ready UCC list:** `GET /api/v1/order/accounts/` (§16) — `order/accounts`, not `account/orders`. |
| Expecting **every** `InvestorUCC` row in `order/accounts` | That endpoint is **trade-eligible only** (§16, **§26**). |
| Expecting a final **`ucc_id` only** from `resolve` after a **new** draft | If **`exists: false`**, get **`client_code` from `draft`**, then **`ucc_id` from** nomination, opt-out verify, or bse finish — no second `resolve` required (§24). |
| Relying on this doc’s §1.1 “`phone_number` / `email`” table for login body | Use **`identifier`** in **`POST /api/v1/auth/login/`** to match the live `LoginAPIView` (or your deployed contract). |

---

*Source of truth: `pivotmoney_backend` view code + `TestingFrontEnd/src/lib/*.js`. Last updated from codebase snapshot — if behaviour diverges, the backend code is authoritative.*
