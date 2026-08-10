# Frontend guide — API v2 onboarding

Base path: `/api/v2/`. All endpoints require **JWT authentication** (`Authorization: Bearer <access_token>`) unless noted otherwise. Tokens are issued by **API v1** (`/api/v1/auth/login/`, `/api/v1/auth/verify/`, `/api/v1/auth/refresh/`).

**Primary routing:** call **`GET /api/v2/profile/validate/`** after each onboarding step. Use `data.next_step` and `data.context` to decide which screen to show. Do not rely on `GET /api/v2/profile/pan/` for the full flow — that endpoint returns a simplified legacy `next_step` (`pan` | `bank` | `dashboard`) for PAN-status screens only.

**Implementation reference:** `pivotmoney_backend/apiv2/views/profile_validate.py` — `ProfileValidateAPI` (GET) and `_determine_onboarding_step()`.

**Legend (request bodies):** **Required** = server returns `400` if absent/invalid when that endpoint is used as documented. **Optional** = may be omitted; server uses defaults or keeps existing values.

---

## 1. Validate (state machine)

### Which page to open after `GET /api/v2/profile/validate/`

Map **`data.next_step`** to a **single** primary screen. Always read **`data.context`** for that step (prefill, flags, optional fields). Re-call validate after **`POST/PATCH /api/v2/profile/update/`** (or other step APIs) to get the new `next_step`.

| `next_step` | What to show the user | `TestingFrontEnd` route (`src/lib/onboardingUtils.js` → `nextStepPath()`) | Notes |
|-------------|------------------------|--------------------------------------------------------------------------|--------|
| `contact_and_pan` | Contact + PAN: collect **phone** and/or **email** if `context.needs_phone` / `needs_email`, then PAN verify | `/onboarding/pan` | — |
| `pan` | Same route: **both** phone and email exist, but **PAN bureau** not finished | `/onboarding/pan` | — |
| `address` | Confirm or edit **correspondence** address; `context.pre_fill` (Cashfree), `is_nri`, `hint` | `/onboarding/address` | — |
| `bank` | Bank: UPI / manual; `context.account_type_options` | `/onboarding/bank` | — |
| `nri_address` | NRI **overseas** address; `existing_indian_address` in `context` | `/onboarding/nri-address` | — |
| `ri_address` | Resident **Indian** address after a **foreign** address; `existing_foreign_address` | `/onboarding/ri-address` | — |
| `details` | Remaining UCC fields; `missing_fields`, `needs_indian_phone_verification`, `indian_phone_optional`, `nri_indian_address_optional` | `/onboarding/details` | — |
| `mf_central` | MF Central CAS link | `/onboarding/mf-central` | **Optional** step: `OnboardingRouter` does not force-redirect (user can skip) |
| `financial_aggregator` | Account Aggregator (Finarkein) | `/onboarding/account-aggregator` | **Optional** (same) |
| `complete` | Onboarding **gate** done — home / invest | `/` (router leaves `/onboarding/*` for home) | — |

**`TestingFrontEnd` shell:** `OnboardingRouter.jsx` reads `nextStep` from session (fed by validate), and redirects from `/` or **wrong** `/onboarding/...` to the path from `nextStepPath(nextStep)`, except for `mf_central` and `financial_aggregator` (no forced redirect so users can browse).

**Other clients (e.g. mobile):** use your own route names, but the **step order and `context` keys** must match this contract.

---

### How `GET /api/v2/profile/validate/` works (backend)

Two parts: **`_determine_onboarding_step(user)`** (returns `next_step` + `context`) and **`ProfileValidateAPI.get`** (builds the full JSON including per-entity `status` fields).

#### A. State machine: `_determine_onboarding_step` (first match wins)

1. **PAN not verified** — if `not pan_verified(user)`: if **real** phone and **email** both present → **`"pan"`**; else → **`"contact_and_pan"`** with `needs_phone` (placeholder email-signup phone), `needs_email` (missing email).
2. **Default bank not verified** — if no `UserBank` default or not `is_verified`: if **no** `user_correspondence` and **no** `user_nri_indian` → **`"address"`** (`pre_fill` from `cashfree` `UserAddress`, `is_nri`, `hint`); else **address rows exist** → **`"bank"`** (`is_nri`, `account_type_options`: NRI gets `SB,CB,NE,NO` else `SB,CB`).
3. **NRI, bank verified, no overseas** — if `NRI-NRE`/`NRI-NRO` and no `user_nri_indian` → **`"nri_address"`** (`existing_indian_address`, `required: true`).
4. **Resident, bank verified, foreign stored without Indian correspondence** — if `user_nri_indian` but no `user_correspondence`, or defensively correspondence country ≠ `IND` → **`"ri_address"`**; edge: neither address → back to **`"address"`** with Cashfree prefill.
5. **`"details"`** — if `gaps_for_ucc_user` is non-empty, or phone is masked/short (`<10` digits), or (Resident with non-Indian phone) needs Indian OTP, etc. Context: `missing_fields`, `needs_indian_phone_verification`, `indian_phone_optional`, `nri_indian_address_optional` (NRI, no Indian correspondence).
6. **`"mf_central"`** — if no `MfCentralCasJourney` row (on `ImportError` importing the model, code treats as no journey needed and **skips** to next check).
7. **`"financial_aggregator"`** — if no `ACTIVE` `ConsentRequest` (same `ImportError` pattern).
8. Else **`"complete"`** with `{}` `context`.

#### B. Per-entity `status` in the same response (backward compatibility)

`ProfileValidateAPI.get` also sets **`pan` / `phone` / `email` / `bank` / `upi` / `address` / `details` / `mf_central` / `financial_aggregator`** with `"verified" \| "pending"`. **Navigation should use `next_step` + `context`.** The `status` block is useful for **progress/ticks**; it is computed separately and may not match `next_step` in every edge case.

#### C. When to call validate

After login, after any **`profile/update`** (or contact/bank/PAN) that changes stored user state, and optionally on focus of an onboarding screen.

---

### `GET /api/v2/profile/validate/`

**Request:** no body. **Auth:** required.

**Response `200` — success**

```json
{
  "success": true,
  "data": {
    "next_step": "contact_and_pan",
    "context": { },
    "pan": { "status": "verified" | "pending" },
    "phone": { "status": "verified" | "pending" },
    "email": { "status": "verified" | "pending" },
    "bank": { "status": "verified" | "pending" },
    "upi": { "status": "verified" | "pending" },
    "address": { "status": "verified" | "pending" },
    "details": {
      "status": "verified" | "pending",
      "missing": ["Primary: First name", "..."]
    },
    "mf_central": { "status": "verified" | "pending" },
    "financial_aggregator": { "status": "verified" | "pending" }
  }
}
```

**Top-level `data` fields — always present**

| Field | Role | Values |
|-------|------|--------|
| `next_step` | **Required** in response (always set) | string enum (see table below) |
| `context` | **Required** in response (may be `{}`) | object; keys depend on `next_step` |
| `pan` … `financial_aggregator` | **Required** in response | each is `{ "status": "verified" \| "pending" }`; `details` also has **`missing`** |

**`details.missing` (and `context.missing_fields` on the `details` step)**

Both lists are produced by the same backend check (`gaps_for_ucc_user` for the **Primary** holder). Strings are **human-readable English labels**, not machine codes. Only entries that fail the check appear; an empty array means no UCC gaps for that checker.

**Possible strings (Primary user)** — exact prefixes are **`Primary:`** (including the space after the colon):

| # | Exact pattern | When it appears |
|---|----------------|-----------------|
| 1 | `Primary: First name` | `ucc_profile.primary_first_name` empty/whitespace |
| 2 | `Primary: Last name` | `ucc_profile.primary_last_name` empty/whitespace |
| 3 | `Primary: Date of birth` | `User.dob` is null |
| 4 | `Primary: PAN` | `User.pan_number` empty/whitespace |
| 5 | `Primary: Phone (10+ digits)` | Fewer than 10 digits in `User.phone_number` after stripping non-digits |
| 6 | `Primary: Email` | No `ucc_profile.primary_email` **and** no `User.email` |
| 7 | `Primary: Investor type (Resident / NRI-NRE / NRI-NRO)` | `User.investor_residency` not one of those three strings |

**If investor type is NRI-NRE or NRI-NRO** (in addition to any of the above that still apply):

| # | Exact pattern | When it appears |
|---|----------------|-----------------|
| 8 | `Primary: Foreign correspondence country (non-IND)` | `ucc_profile.country` missing, empty, or `"IND"` (NRI must have a **non-India** main correspondence country) |
| 9 | `Primary: Foreign TIN / tax ID (NRI)` | `ucc_profile.primary_tax_id` empty/whitespace |

**If investor type is Resident** (not NRI; in addition to rows 1–7 as applicable):

| # | Exact pattern | When it appears |
|---|----------------|-----------------|
| 10 | `Primary: Correspondence address line 1` | `ucc_profile.address_line_1` empty/whitespace |
| 11 | `Primary: City` | `ucc_profile.city` empty/whitespace |
| 12 | `Primary: State` | `ucc_profile.state` empty/whitespace |
| 13 | `Primary: Pincode` | `ucc_profile.pincode` empty/whitespace |

**Always (any residency), until satisfied:**

| # | Exact pattern | When it appears |
|---|----------------|-----------------|
| 14 | `Primary: Bank account number` | No digits on default `UserBank` and no `ucc_profile.bank_acc_num` |
| 15 | `Primary: IFSC` | No IFSC on default bank and no `ucc_profile.ifsc_code` |
| 16 | `Primary: Bank account type (SB/CB/NE/NO)` | No account type on default bank and no `ucc_profile.bank_acc_type` |
| 17 | `Primary: Digital signature (draw in beta profile)` | `ucc_profile.primary_signature` missing or string length **&lt; 80** |

**Not in this list:** occupation, income slab, gender, etc. may still be required for BSE or shown in UI, but **this** `missing` array only reflects `gaps_for_ucc_user` in `user/beta_ucc.py`. If the product adds new checks there, new strings can appear — treat unknown `"Primary: …"` entries as blocking until resolved.

**`next_step` values (in typical order)**

| `next_step` | Meaning |
|-------------|---------|
| `contact_and_pan` | Collect missing phone and/or email, then PAN |
| `pan` | Phone + email present; PAN bureau still pending |
| `address` | Confirm/edit address from PAN / correspondence |
| `bank` | Bank / UPI or manual account |
| `nri_address` | NRI: overseas address required |
| `ri_address` | Resident: **Indian correspondence address mandatory** after they saved a **foreign** address (see below) |
| `details` | Remaining UCC fields (and optional phone/address per `context`) |
| `mf_central` | Optional MF Central CAS linking |
| `financial_aggregator` | Optional Account Aggregator (Finarkein) |
| `complete` | Onboarding gate satisfied |

**`context` by `next_step` — key mandatory vs optional**

| `next_step` | Context keys | Required in `context`? |
|-------------|--------------|-------------------------|
| `contact_and_pan` | `needs_phone`, `needs_email` | Both always present (boolean). |
| `pan` | same | Both always present. |
| `address` | `pre_fill`, `is_nri`, `hint` | All always present; `pre_fill` may be **`null`** (no Cashfree address on file). |
| `bank` | `is_nri`, `account_type_options` | Both always present; `account_type_options` is a non-empty string array. |
| `nri_address` | `existing_indian_address`, `required` | `required` is **`true`** when this step is returned. `existing_indian_address` may be **`null`** if there is no Indian correspondence record yet. |
| `ri_address` | `existing_foreign_address`, `required` | **`required` is always `true`** when this step is returned. **`existing_foreign_address`** is **mandatory content for the UI**: show it as the address they already entered (foreign); the user must supply a **separate Indian** correspondence address (see flow below). May be `null` only in edge/defensive paths. |
| `details` | `missing_fields`, `needs_indian_phone_verification`, `indian_phone_optional`, `nri_indian_address_optional` | `missing_fields` mirrors the same list as `details.missing`. Booleans are always present (`true`/`false`). |
| `mf_central` / `financial_aggregator` | e.g. `optional` | Keys may vary; treat step as skippable in product UX. |
| `complete` | — | `context` is `{}`. |

Address objects in `context` use: `address_line_1`, `address_line_2`, `address_line_3`, `city`, `state`, `pincode`, `country_code`, `country_name`.

---

### Resident (Indian) enters a **foreign** address on the address page — what the API does next

This matches **Scenario F** in `Architecture/onboard.md`.

1. **After PAN** the user is usually on `next_step: "address"` with `context.pre_fill` from PAN (Indian), `is_nri: false`, and a `hint` to confirm correspondence.

2. If the user submits an address with **`country` not `IND`** via **`POST/PATCH /api/v2/profile/update/`** (in `extended_profile`), the server syncs that address to **`UserAddress` with type `user_nri_indian`** (foreign / overseas row). It does **not** create a proper Indian **`user_correspondence`** row from that submission alone.

3. **`GET /profile/validate/`** then:
   - Still has **no** verified bank → next step is **`bank`** (having a foreign-only stored address counts as “address captured” for the pre-bank gate: the server does **not** keep them on `address` forever just because correspondence is missing).
   - After **bank is verified**, for a **Resident** with **no** `user_correspondence` but **yes** `user_nri_indian` (the foreign address), validate returns  
     **`next_step: "ri_address"`**  
     with  
     **`context.existing_foreign_address`** = that saved foreign address (same shape as other address dicts), and **`context.required: true`**.

4. **What you must collect on the `ri_address` screen:** a full **Indian** correspondence address. The client should **`POST/PATCH /profile/update/`** with `extended_profile` where **`country`** is **`IND`** and Indian line/city/state/pincode are filled. The server then creates/updates **`user_correspondence`** and (for Residents) may clear stale `user_nri_indian` when appropriate per sync rules.

5. **Optional UX aid — `GET /profile/details/`:** `data.address_info` includes:
   - **`needs_indian_address`**: `true` when residency is Resident, the main correspondence slot looks **non-Indian**, and optional Indian `ind_*` slot is not filled — use to show warnings on profile/address UI.
   - **`guidance`**: human-readable string explaining what is missing.

6. After Indian correspondence is saved and other gates pass, validate moves to **`details`** / **`complete`** as usual. **`needs_indian_phone_verification`** on the details step is a **separate** rule (Resident with **non-+91** phone on account), not the same as `ri_address`.

---

## 2. Contact

### `GET /api/v2/profile/contact/`

**Request:** no body. **Auth:** required.

**Response `200` — field requirements**

| Field | Required in response? | Meaning |
|-------|------------------------|---------|
| `success` | Yes | `true` |
| `data.needs_secondary_otp` | Yes | If `true`, user must complete phone or email before PAN verify. |
| `data.secondary_kind` | Yes | `"phone"` \| `"email"` \| `null` — which channel is blocking. |
| `data.phone_country_code` | Yes | e.g. `"+91"` or `null`. |

```json
{
  "success": true,
  "data": {
    "needs_secondary_otp": true,
    "secondary_kind": "phone" | "email" | null,
    "phone_country_code": "+91" | null
  }
}
```

Use before PAN verify: if `needs_secondary_otp` is true, collect and verify the `secondary_kind` channel first.

---

### `POST /api/v2/profile/contact/otp/`

Send OTP to phone (Indian flow → SMS) or email.

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `kind` | **Yes** | Must be exactly `"phone"` or `"email"`. |
| `value` | **Yes** | Non-empty. Phone: normalized to 10-digit Indian. Email: valid format. |

```json
{
  "kind": "phone" | "email",
  "value": "9876543210 or user@example.com"
}
```

- **Phone:** digits normalized to 10-digit Indian number internally; SMS only if server is configured.
- **Email:** must be valid email format.

**Response `201` — success** — `success` and `message` are always set.

```json
{ "success": true, "message": "OTP sent to phone." }
```
or `"OTP sent to email."`

**Errors:** `400` invalid `kind` / value / phone; `503` SMS or email send failure.

---

### `POST /api/v2/profile/contact/otp/verify/`

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `kind` | **Yes** | `"phone"` or `"email"`. |
| `value` | **Yes** | Must match the value used when sending OTP. |
| `otp` | **Yes** | Non-empty string (6-digit OTP from SMS/email). |

```json
{
  "kind": "phone" | "email",
  "value": "same value used when sending OTP",
  "otp": "6-digit string"
}
```

**Response `200`**

```json
{ "success": true, "message": "Contact verified and saved." }
```

**Errors:** `400` invalid/expired OTP; `409` with `code`: `phone_exists` | `email_exists`.

---

### `POST /api/v2/profile/contact/phone/save/`

Save a **non-Indian** phone without OTP (must not be `+91`).

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `country_code` | **Yes** | Non-empty; must **not** be `"+91"` (Indian numbers must use OTP). |
| `phone_number` | **Yes** | Non-empty local part (combined with `country_code` for storage). |

```json
{
  "country_code": "+44",
  "phone_number": "7123456789"
}
```

**Response `200`**

```json
{ "success": true, "message": "Phone saved." }
```

**Errors:** `400` if `country_code` is `+91` (use OTP flow) or missing fields; `409` `phone_exists`.

---

## 3. PAN (Cashfree bureau)

### `GET /api/v2/profile/pan/`

**Request:** no body. **Auth:** required.

**Response `200` — fields**

| Field | Required in response? | Notes |
|-------|------------------------|-------|
| `success` | Yes | `true` |
| `data.pan_verified` | Yes | boolean |
| `data.bank_verified` | Yes | boolean |
| `data.next_step` | Yes | **Legacy** coarse step: `pan` \| `bank` \| `dashboard` — use **`GET /profile/validate/`** for product routing. |
| `data.pan_number_masked` | Yes | string or `null` |
| `data.primary_bank` | Yes | object or **`null`** |

```json
{
  "success": true,
  "data": {
    "pan_verified": true,
    "bank_verified": false,
    "next_step": "pan" | "bank" | "dashboard",
    "pan_number_masked": "XXXXXX1234" | null,
    "primary_bank": { } | null
  }
}
```

`primary_bank` when present matches the **bank object** shape in section 5 (`id`, `account_number_masked`, `ifsc_code`, `bank_name`, `account_type`, `upi_id`, `is_default`, `is_verified`).

---

### `POST /api/v2/profile/pan/verify/`

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `pan_number` | **Yes** | Exactly **10** characters after strip; typical PAN format. |

```json
{
  "pan_number": "ABCDE1234F"
}
```

Must be exactly 10 characters (validated as PAN format on server).

**Response `200` — bureau or DB prefill success**

On success, **`success`** and **`message`** are always set. **`data`** keys vary slightly by path; common keys:

| Field | Required on success? | Notes |
|-------|---------------------|-------|
| `data.onboarding_status` | Usually yes | e.g. internal status `"BANK"`. |
| `data.pan_number` | Yes | Verified PAN string. |
| `data.kyc_id` | When KYC row exists | integer |
| `data.kyc_status` | When KYC row exists | e.g. `"VALID"` |
| `data.is_name_matched` | When KYC row exists | boolean |
| `data.is_dob_matched` | When KYC row exists | boolean |
| `data.name_at_source` | Optional | From bureau / snapshot. |
| `data.dob_at_source` | Optional | From bureau / snapshot. |
| `data.prefilled_from_db` | Optional | **`true`** only on DB-prefill path; omit or `false` on Cashfree bureau path. |

```json
{
  "success": true,
  "message": "…",
  "data": {
    "onboarding_status": "BANK",
    "pan_number": "ABCDE1234F",
    "kyc_id": 123,
    "kyc_status": "VALID",
    "is_name_matched": true,
    "is_dob_matched": true,
    "name_at_source": "…",
    "dob_at_source": "…",
    "prefilled_from_db": false
  }
}
```

`prefilled_from_db` is `true` when PAN was matched to an in-system snapshot and Cashfree was skipped.

**Errors**

- `400` invalid PAN, `contact_missing` with `data.secondary_kind`, or bureau failure with optional `data` KYC fields.
- `409` `user_pan_exists` | `pan_exists` with `data` as implemented in `ProfilePanBureauVerifyAPIView`.

After success, call **`GET /profile/validate/`** again.

---

## 4. Profile read / update (address, UCC fields, signature)

### `GET /api/v2/profile/details/`

**Request:** no body. **Auth:** required.

**Response `200` — top-level**

| Field | Required? | Notes |
|-------|------------|-------|
| `success` | Yes | `true` |
| `onboarding_status` | Yes | string (duplicate of inner for convenience) |
| `data` | Yes | Large user + readiness object (see below). |

**`data` object** — all keys below are **normally present** on success; nested objects may be empty.

| Field | Required? | Notes |
|-------|------------|-------|
| `id`, `name`, `phone_number`, `email`, … | Yes | Core user fields from `_serialize_user`. |
| `ucc_profile` | Yes | dict (may be empty). |
| `onboarding_status`, `profile_issues`, `identity_verified`, `profile_complete` | Yes | Readiness helpers. |
| `profile_requirements` | Yes | Section checklist from server. |
| `validate` | Yes | boolean — profile passed internal complete gate. |
| `holders` | Yes | array (may be empty). |
| `payment_upi_id` | Yes | string (may be empty). |
| `address_info` | Yes | See **Resident + foreign address** section above for `needs_indian_address` / `guidance`. |

```json
{
  "success": true,
  "onboarding_status": "PROFILE",
  "data": {
    "id": "uuid-string",
    "name": "…",
    "phone_number": "…",
    "pan_number": "…",
    "dob": "YYYY-MM-DD",
    "email": "…",
    "investor_residency": "Resident" | "NRI-NRE" | "NRI-NRO" | null,
    "ucc_profile": { },
    "default_bank": { },
    "kyc": { },
    "kyc_done": true,
    "needs_kyc_verification": false,
    "kyc_name_mismatch": false,
    "name_suggested_from_pan": null,
    "ucc_accounts": [],
    "onboarding_status": "…",
    "profile_issues": [],
    "identity_verified": true,
    "profile_complete": false,
    "profile_requirements": { },
    "validate": false,
    "holders": [],
    "payment_upi_id": "",
    "address_info": {
      "pan_address": null,
      "correspondence_address": null,
      "indian_address": null,
      "residency": null,
      "is_nri": false,
      "correspondence_is_indian": false,
      "has_overseas_address": false,
      "has_indian_address": false,
      "can_use_pan_address_as_current": false,
      "needs_overseas_address": false,
      "needs_indian_address": false,
      "guidance": "…"
    }
  }
}
```

Use `address_info` and `profile_requirements` / `profile_issues` to drive address and details screens. `ucc_profile` holds flattened UCC keys (including `address_line_*`, `country`, optional `ind_*` for NRI Indian address, occupation, income, signature, etc.).

---

### `POST` or `PATCH /api/v2/profile/update/`

Forwards to the internal beta profile service after normalizing the body. Prefer **JSON** body.

**Request — top-level keys (all optional unless your flow needs them)**

| Field | Required? | Notes |
|-------|------------|-------|
| `investor_residency` | Optional | `"Resident"` \| `"NRI-NRE"` \| `"NRI-NRO"`. |
| `extended_profile` | Optional | **Primary payload** for UCC keys; merged into `ucc_profile`. |
| `phone_number`, `dob`, `pan_number` | Optional | Direct `User` field updates when accepted by beta service. |

**Inside `extended_profile` (common onboarding keys)** — **none are required by HTTP** (server accepts partial PATCH), but **`gaps_for_ucc_user`** (see §1 `missing` list) defines what is **blocking** until filled. Typical mappings:

| Key | Blocking for `missing`? | Notes |
|-----|-------------------------|-------|
| `primary_first_name`, `primary_last_name` | Yes if empty | |
| `address_line_1`, `city`, `state`, `pincode` | Yes for **Resident** if empty | For NRI, main slot must be **non-IND** country + TIN rules instead. |
| `country` | Yes for NRI | Must be non-`IND` for NRI main correspondence. |
| `primary_tax_id` | Yes for NRI | Foreign TIN. |
| `primary_signature` | Yes if &lt; 80 chars | Base64 image string. |
| `primary_occupation`, `primary_income_slab`, `primary_gender`, … | **Not** in `missing` list | Still used for UCC / BSE; send when product requires. |
| `ind_address_line_1`, `ind_city`, `ind_state`, `ind_pincode`, … | Optional | NRI **optional Indian** address slot; syncs to `user_correspondence` when main slot is overseas. |

**Common request body (JSON)**

```json
{
  "investor_residency": "Resident",
  "extended_profile": {
    "primary_first_name": "…",
    "address_line_1": "…",
    "city": "…",
    "state": "…",
    "pincode": "…",
    "country": "IND",
    "primary_occupation": "…",
    "primary_income_slab": "…",
    "primary_signature": "data:image/png;base64,..."
  },
  "phone_number": "optional direct field",
  "dob": "YYYY-MM-DD",
  "pan_number": "optional"
}
```

- **`extended_profile`:** merged into the user’s UCC profile; address lines and `country` sync to `UserAddress` (`user_correspondence` vs `user_nri_indian`) per server rules.
- Invalid merges can return `400` with `message` from server.

**Response `200` — success**

```json
{
  "success": true,
  "onboarding_status": "UCC",
  "data": {
    "status": "ok",
    "user": {
      "…same enriched shape as GET details…"
    }
  }
}
```

**Errors:** `400` validation / beta errors; `401` if internal profile service rejects session.

Then call **`GET /profile/validate/`**.

---

## 5. Bank and residency

### `GET /api/v2/profile/bank/`

**Request:** no body. **Auth:** required.

**Response `200` — fields**

| Field | Required? | Notes |
|-------|------------|-------|
| `success` | Yes | `true` |
| `data.bank_verified` | Yes | boolean |
| `data.primary_bank` | Yes | object or **`null`** if no default bank row |
| `data.suggested_flow` | Yes | `"collect_bank"` \| `"dashboard"` |
| `data.collect_bank` | Yes | object with `upi_lookup_first`, `manual_fallback`, `hint` |

```json
{
  "success": true,
  "data": {
    "bank_verified": false,
    "primary_bank": {
      "id": 1,
      "account_number_masked": "*******1234",
      "ifsc_code": "HDFC0001234",
      "bank_name": "…",
      "account_type": "SB",
      "upi_id": "name@paytm",
      "is_default": true,
      "is_verified": false
    },
    "suggested_flow": "collect_bank" | "dashboard",
    "collect_bank": {
      "upi_lookup_first": true,
      "manual_fallback": true,
      "hint": "If the user has no UPI ID, open the manual bank form."
    }
  }
}
```

**`data.primary_bank` object** (when not `null`) — keys returned by `bank_to_public_dict`:

| Field | Always present? | Notes |
|-------|------------------|-------|
| `id` | Yes | integer PK |
| `account_number_masked` | Yes | masked string |
| `ifsc_code` | Yes | uppercase string |
| `bank_name` | Yes | may be empty string |
| `account_type` | Yes | may be empty until set |
| `upi_id` | Yes | may be empty string |
| `is_default` | Yes | boolean |
| `is_verified` | Yes | boolean |

**Response `403`** if PAN not verified:

```json
{
  "success": false,
  "message": "Complete PAN verification before bank onboarding.",
  "data": { "next_step": "pan" }
}
```

---

### `PATCH /api/v2/profile/bank/`

Update draft / primary bank fields before verification (optional).

**Request body (JSON)** — **all keys optional**; only send fields to change. At least one field is expected in practice.

| Field | Required? |
|-------|------------|
| `bank_name`, `account_type`, `upi_id`, `account_number`, `ifsc_code` | **Optional** (each) |

```json
{
  "bank_name": "…",
  "account_type": "SB",
  "upi_id": "name@paytm",
  "account_number": "…",
  "ifsc_code": "HDFC0001234"
}
```

**Response `200`**

```json
{
  "success": true,
  "data": {
    "bank": { }
  }
}
```

Shape matches **primary_bank** above.

---

### `POST /api/v2/profile/bank/upi/lookup/`

Penny-drop preview; does not persist bank as verified by itself.

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `upi_id` **or** `vpa` | **Yes** (one of) | Non-empty UPI ID containing `@`. |

```json
{
  "upi_id": "name@paytm"
}
```

`vpa` is accepted as an alias for `upi_id`.

**Response `200`**

```json
{
  "success": true,
  "data": {
    "fetched": {
      "verification_status": "VALID" | "…",
      "message": "",
      "account_number": "…",
      "ifsc_code": "HDFC0001234",
      "bank_name": "…",
      "name_at_bank": "…",
      "vpa": "…",
      "branch": "…",
      "city": "…",
      "state": "…",
      "ifsc_details": { }
    }
  }
}
```

The server strips the raw Cashfree payload from this response; use **`upi/confirm/`** to persist.

**`data.fetched` keys** — subset of normalized penny-drop fields; values may be `null` depending on upstream:

| Key | Typical presence |
|-----|-------------------|
| `verification_status` | Usually set (`VALID` / other). |
| `message`, `account_number`, `ifsc_code`, `bank_name`, `name_at_bank`, `vpa` | Optional / upstream-dependent. |
| `branch`, `city`, `state`, `ifsc_details` | Optional. |

---

### `POST /api/v2/profile/bank/upi/confirm/`

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `upi_id` **or** `vpa` | **Yes** | Non-empty. |
| `bank_name` | Optional | Override display / stored bank name. |
| `account_type` | Optional | e.g. `SB`, `CB`, `NE`, `NO`. |
| `investor_residency` | Optional | Strongly **recommended** on bank step; `RI`/`NRE`/`NRO` aliases accepted. |

```json
{
  "upi_id": "name@paytm",
  "bank_name": "optional override",
  "account_type": "SB",
  "investor_residency": "Resident" | "NRI-NRE" | "NRI-NRO" | "RI" | "NRE" | "NRO"
}
```

`investor_residency` is optional but recommended on the bank step.

**Response `200`**

```json
{
  "success": true,
  "data": {
    "bank": { },
    "next_step": "profile",
    "onboarding_status": "PROFILE"
  }
}
```

Note: `next_step: "profile"` here means **legacy user-status wording**, not `GET /profile/validate/` routing. Always re-fetch **`GET /profile/validate/`** for UI routing.

---

### `POST /api/v2/profile/bank/manual/`

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `account_number` | **Yes** | Non-empty after whitespace strip. |
| `ifsc_code` | **Yes** | **11** characters, valid IFSC shape. |
| `bank_name` | Optional | |
| `account_type` | Optional | e.g. `SB`, `NE`, … |
| `upi_id` | Optional | |
| `investor_residency` | Optional | Same as UPI confirm. |
| `skip_verification` | Optional | Default `false`; `true` skips Cashfree verify (ops escape hatch). |

```json
{
  "account_number": "…",
  "ifsc_code": "HDFC0001234",
  "bank_name": "optional",
  "account_type": "SB",
  "upi_id": "optional",
  "investor_residency": "Resident",
  "skip_verification": false
}
```

**Response `200`**

```json
{
  "success": true,
  "data": {
    "bank": { },
    "next_step": "profile" | "bank",
    "name_at_bank": "…",
    "onboarding_status": "PROFILE"
  }
}
```

`next_step` stays `"bank"` if verification did not complete (`bank.is_verified` false).

**Errors `400`:** may include `data.verification` with Cashfree payload when available.

---

### `GET /api/v2/profile/residency/`

**Request:** no body.

**Response `200`**

| Field | Required? |
|-------|------------|
| `success`, `data.investor_residency`, `data.options` | Yes — `options` is a fixed-length array of `{ value, label }`. |

```json
{
  "success": true,
  "data": {
    "investor_residency": "Resident",
    "options": [
      { "value": "Resident", "label": "Resident Individual (RI)" },
      { "value": "NRI-NRE", "label": "NRI — NRE" },
      { "value": "NRI-NRO", "label": "NRI — NRO" }
    ]
  }
}
```

---

### `POST /api/v2/profile/residency/`

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `investor_residency` **or** `residency` | **Yes** (one of) | Must normalize to `Resident` \| `NRI-NRE` \| `NRI-NRO`. |

```json
{
  "investor_residency": "NRI-NRE"
}
```

Alias: `residency`. Short codes `RI`, `NRE`, `NRO` are normalized.

**Response `200`**

```json
{
  "success": true,
  "data": { "investor_residency": "NRI-NRE" }
}
```

---

## 6. Optional steps after validate (`mf_central`, `financial_aggregator`)

### `POST /api/v2/mf-central/initiate/`

**Request body (JSON)** — logical requirements (server fills from user when omitted):

| Field | Required? | Notes |
|-------|------------|-------|
| `pan` | **Conditionally required** | If absent, user must already have **10-char** `pan_number`; else `400`. |
| `email`, `mobile` | **At least one path** | If both missing on user and body, **`400`** (“Either mobile or email required”). If `mobile` present, server may clear email for MF Central API compatibility. |
| `from_date` / `fromDate`, `to_date` / `toDate` | Optional | Default statement window from server. |
| `callback_url` | Optional | Server may substitute default MFC callback URL. |

```json
{
  "pan": "ABCDE1234F",
  "email": "user@example.com",
  "mobile": "919876543210",
  "from_date": "YYYY-MM-DD",
  "to_date": "YYYY-MM-DD",
  "callback_url": "https://…"
}
```

**Response `200`**

| Field | Required on success? | Notes |
|-------|----------------------|-------|
| `data.redirect_url` | Yes | Hosted MF Central URL to open. |
| `data.client_ref_no` | Yes | Reference for support / logs. |
| `data.journey` | Yes | Object with `id`, `client_ref_no`, `req_id`, `pan`, `email`, `mobile`, `notes`, ISO timestamps. |

```json
{
  "success": true,
  "data": {
    "redirect_url": "https://…",
    "client_ref_no": "…",
    "journey": {
      "id": 1,
      "client_ref_no": "…",
      "req_id": "…",
      "pan": "…",
      "email": "…",
      "mobile": "…",
      "notes": null,
      "updated_at": "…",
      "created_at": "…"
    }
  }
}
```

Open `redirect_url` in browser / WebView. Then poll status.

---

### `GET /api/v2/mf-central/status/`

**Request:** no body.

**Response `200`**

| Field | Required? | Notes |
|-------|------------|-------|
| `data.has_journey` | Yes | boolean |
| `data.journey` | Yes | object or **`null`** |

```json
{
  "success": true,
  "data": {
    "has_journey": true,
    "journey": { }
  }
}
```

`journey` is `null` if none.

---

### `POST /api/v2/finarkein/initiate/`

**Request body (JSON)** — overrides optional; **PAN and phone** must be resolveable from body **or** user:

| Field | Required? | Notes |
|-------|------------|-------|
| `pan` | **Conditionally required** | From body or `User.pan_number`; else `400`. |
| `phone` / `mobile` / `mobileNumber` / `mobile_number` | **Conditionally required** | From body or `User.phone_number`; else `400`. |
| `dob`, `email`, `name` | Optional | Fall back to user. |
| `redirectUrl` / `redirect_url`, `consentStyle`, `consentTemplates`, `applicationNo`, `accountFilters`, `clientUserId`, … | Optional | Passed through to Finarkein when present. |

```json
{
  "pan": "ABCDE1234F",
  "phone": "+919876543210",
  "dob": "YYYY-MM-DD",
  "email": "…",
  "name": "…",
  "redirectUrl": "https://…",
  "consentStyle": "…",
  "consentTemplates": [],
  "applicationNo": "…",
  "accountFilters": {},
  "clientUserId": "…"
}
```

**Response:** wraps Finarkein service result — **`success`**, **`statusCode`**, plus provider-specific keys (e.g. redirect / request id). Inspect the live response in your environment.

```json
{
  "success": true,
  "statusCode": 200,
  "…additional keys from FinarkeinService.initiate_consent…"
}
```

---

### `POST /api/v2/finarkein/pull/`

**Request body (JSON)**

| Field | Required? | Notes |
|-------|------------|-------|
| `request_id` **or** `requestId` | **Yes** | Non-empty string from initiate flow. |
| `maxWaitSeconds` / `max_wait_seconds` | Optional | Default **180**. |
| `intervalSeconds` / `interval_seconds` | Optional | Default **2**. |
| `skipPoll` / `skip_poll` | Optional | Default false. |
| `forceRefresh` / `force_refresh` | Optional | Default false. |

```json
{
  "request_id": "uuid-or-id-from-initiate",
  "maxWaitSeconds": 180,
  "intervalSeconds": 2,
  "skipPoll": false,
  "forceRefresh": false
}
```

**Response:** `{ "success": bool, "statusCode": number, … }` from service.

---

### `GET /api/v2/finarkein/status/`

**Request:** no body.

**Response `200`**

| Field | Required? | Notes |
|-------|------------|-------|
| `data.has_consent` | Yes | boolean |
| `data.consent` | Yes | object or **`null`** |

```json
{
  "success": true,
  "data": {
    "has_consent": true,
    "consent": {
      "request_id": "…",
      "status": "ACTIVE",
      "provider": "…",
      "redirect_url": "…",
      "created_at": "…",
      "updated_at": "…"
    }
  }
}
```

If no consent: `has_consent: false`, `consent: null`.

---

## 7. Recommended client flow

1. After login, **`GET /profile/validate/`** → route using `next_step`.
2. Contact + PAN: `GET /profile/contact/` → OTP or phone save → **`POST /profile/pan/verify/`** → validate.
3. Address / bank / NRI / RI pages: **`POST /profile/update/`** and bank endpoints as in `Architecture/onboard.md`.
4. After each successful mutation, **`GET /profile/validate/`** again.
5. Optional: MF Central / Finarkein when `next_step` indicates; then validate until `complete`.

---

## 8. Error shape (common)

Many endpoints return:

```json
{
  "success": false,
  "message": "Human-readable message",
  "code": "optional_machine_code",
  "data": { }
}
```

HTTP status: `400` validation, `403` forbidden (e.g. PAN not done), `409` conflict, `502`/`503` upstream / configuration.
