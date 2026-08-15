# SIP (Systematic Investment Plan) Flow — Frontend Integration Guide

## Overview

An SIP requires three things before BSE can register it:
1. A valid **UCC** (investor account on BSE)
2. A bank-authorised **e-Mandate** (UPI Autopay / eNACH / NACH)
3. A **first instalment payment** taken today (immediately)

```
UCC Setup → Amount + Schedule → New Mandate → Bank Auth → SIP Registered + First Payment → Poll → Success
```

> **Key rule:** Every new SIP always gets its own fresh mandate — existing approved mandates are never reused. This keeps SIPs independent and cancellable.

---

## Base URL

- apiv2 (UCC + mandate + SIP): `/api/v2/`
- apiv1 (payment for first instalment): `/api/v1/`

Authentication: `Authorization: Bearer <access_token>` on every request.

---

## Complete Step-by-Step Flow

### Step 0 — Fetch poll configuration (once on wizard open)

```
GET /api/v2/trade/payment-poll-config/
```

**Response**
```json
{
  "success": true,
  "data": {
    "max_wait_seconds": 300,
    "poll_interval_seconds": 30
  }
}
```

Used to drive the countdown timer during first-payment polling.

---

### Steps 1–3 — UCC Setup (identical to lumpsum order)

Refer to `order.md` Steps 1–3 for the full UCC wizard (resolve → draft → nomination → OTP). The result is a `ucc_id` and `client_code`.

Short version:
- `POST /api/v2/trade/ucc/resolve/` → if `investment_ready: true` → use directly
- Otherwise: draft → nomination → OTP → obtain `ucc_id`

---

### Step 4 — User enters SIP details

Collect these fields in your UI before calling the mandate APIs:

| Field | Type | Notes |
|---|---|---|
| `amount` | number | Monthly SIP amount in ₹ |
| `frequency` | string | `"monthly"` / `"quarterly"` / `"weekly"` / `"daily"` — default: `"monthly"` |
| `txn_day` | int (1–28) | Day of month for recurring debits — default: 5 |
| `installments` | int | Number of installments — default: 12 |

> The **first instalment** is always charged **today** (instantly). The second debit lands on the chosen `txn_day` — BSE enforces a minimum 30-day gap, so if the day is within 30 days it may skip one cycle.

---

### Step 5 — Load mandate status

Check available bank accounts and whether any pending mandate exists for this UCC.

```
GET /api/v2/trade/mandate/status/?client_code=PM_AB1234&sip_amount=5000
```

**Query params:**

| Param | Required | Notes |
|---|---|---|
| `client_code` | Yes (or `ucc_id`) | From UCC wizard |
| `ucc_id` | Yes (or `client_code`) | UUID from UCC wizard |
| `sip_amount` | No | Used to calculate suggested mandate cap |

**Response**
```json
{
  "success": true,
  "data": {
    "client_code": "PM_AB1234",
    "ucc_id": "a1b2c3d4-...",
    "mandates": [
      {
        "id": 3,
        "mandate_id": "BSEM202401150001",
        "mandate_type": "U",
        "status": "AWAITING_AUTH",
        "bse_mandate_status": "Created",
        "amount_limit": 120000.0,
        "bank_acc_num": "50100123456789",
        "bank_name": "HDFC Bank",
        "ifsc_code": "HDFC0001234",
        "start_date": "2024-01-15",
        "end_date": "2034-01-15",
        "mode": "DD",
        "frequency": "AS AND WHEN PRESENTED",
        "authorization_url": "https://upi.npci.org.in/mandate/...",
        "authorization_sent_at": "2024-01-15T10:30:00Z",
        "authorized_at": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
      }
    ],
    "usable_mandate": null,
    "bank_accounts": [
      {
        "id": 5,
        "account_number": "50100123456789",
        "account_type": "SA",
        "ifsc_code": "HDFC0001234",
        "bank_name": "HDFC Bank",
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

**Frontend logic:**
- `usable_mandate` is always ignored — always create a fresh mandate for each SIP.
- If `mandates` contains an entry with `status: "AWAITING_AUTH"` or `status: "PENDING"`, offer to resume that mandate (go to Step 7 — Authorize).
- Otherwise go to Step 6 — Register new mandate.
- Pre-fill bank selector with the account where `is_default: true`.
- Pre-fill mandate cap with `suggested_cap` (≈ 24× the SIP amount, capped at ₹10L).

---

### Step 6 — Register a new mandate

```
POST /api/v2/trade/mandate/register/
```

**Request (UPI Autopay — recommended)**
```json
{
  "client_code": "PM_AB1234",
  "bank_account_id": 5,
  "max_amount": 120000,
  "mandate_type": "U",
  "upi_id": "user@okaxis"
}
```

**Request (eNACH — netbanking/debit card)**
```json
{
  "client_code": "PM_AB1234",
  "bank_account_id": 5,
  "max_amount": 120000,
  "mandate_type": "N"
}
```

**Request (NACH physical form)**
```json
{
  "client_code": "PM_AB1234",
  "bank_account_id": 5,
  "max_amount": 120000,
  "mandate_type": "X"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `client_code` | string | Yes (or `ucc_id`) | From UCC wizard |
| `ucc_id` | UUID string | Yes (or `client_code`) | From UCC wizard |
| `bank_account_id` | int | Yes | `id` from `bank_accounts` list |
| `max_amount` | number | Yes | Maximum per-debit limit in ₹; must be ≥ SIP amount |
| `mandate_type` | `"U"` \| `"N"` \| `"X"` | No | Defaults to `"U"` (UPI Autopay) |
| `upi_id` | string | If type `"U"` | VPA e.g. `name@okaxis` — required for UPI Autopay |
| `frequency` | string | No | Defaults to `"AS AND WHEN PRESENTED"` |
| `mode` | string | No | Auto-selected by backend (`"DD"` for UPI, `"ACH"` for eNACH) |

**Response (success)**
```json
{
  "success": true,
  "data": {
    "id": 4,
    "mandate_id": "BSEM202401150002",
    "mandate_type": "U",
    "status": "AWAITING_AUTH",
    "bse_mandate_status": "Created",
    "amount_limit": 120000.0,
    "bank_acc_num": "50100123456789",
    "bank_name": "HDFC Bank",
    "ifsc_code": "HDFC0001234",
    "start_date": "2024-01-15",
    "end_date": "2034-01-15",
    "mode": "DD",
    "frequency": "AS AND WHEN PRESENTED",
    "authorization_url": "https://upi.npci.org.in/mandate/auth?ref=...",
    "authorization_sent_at": "2024-01-15T10:30:00Z",
    "authorized_at": null,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

**Response (BSE auth failure)**
```json
{
  "success": false,
  "error_code": "BSE_AUTH_FAILED",
  "message": "BSE login is currently unavailable..."
}
```

Store `mandate_id` and `authorization_url`. Go to Step 7.

---

### Step 7 — User authorises the mandate at their bank

**UPI Autopay (type `"U"`):**
- BSE sends a UPI collect request to the VPA provided.
- The user approves it in their UPI app (GPay, PhonePe, Paytm, etc.).
- Do **not** open any URL — just tell the user to check their UPI app.
- Begin polling (Step 8).

**eNACH (type `"N"`):**
- Open `authorization_url` in a new browser tab automatically.
- The user completes netbanking / debit card authentication at their bank.
- Begin polling (Step 8).

**NACH physical (type `"X"`):**
- Download / display the NACH form for the user to sign and submit physically.
- Mandate approval may take several days.

---

### Step 8 — Poll mandate status

Poll every 5 seconds until `status === "APPROVED"` or a terminal state. Maximum poll window: 10 minutes.

```
GET /api/v2/trade/mandate/poll/?mandate_id=BSEM202401150002
```

**Response**
```json
{
  "success": true,
  "data": {
    "id": 4,
    "mandate_id": "BSEM202401150002",
    "mandate_type": "U",
    "status": "APPROVED",
    "bse_mandate_status": "Approved",
    "amount_limit": 120000.0,
    "bank_acc_num": "50100123456789",
    "bank_name": "HDFC Bank",
    "ifsc_code": "HDFC0001234",
    "authorization_url": "https://upi.npci.org.in/mandate/auth?ref=...",
    "authorized_at": "2024-01-15T10:32:15Z",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:32:15Z"
  }
}
```

**Mandate status values:**

| Status | Meaning | Action |
|---|---|---|
| `AWAITING_AUTH` | Waiting for user bank approval | Keep polling |
| `PENDING` | BSE processing | Keep polling |
| `APPROVED` | Ready — proceed to register SIP | Go to Step 9 |
| `REJECTED` | Bank declined | Show error, offer to create new mandate |
| `EXPIRED` | Approval window closed | Show error, offer to create new mandate |
| `CANCELLED` | Mandate cancelled | Show error, offer to create new mandate |

---

### Step 9 — Register the SIP

Call immediately after mandate `status === "APPROVED"`.

```
POST /api/v2/trade/sip/create/
```

**Request**
```json
{
  "client_code": "PM_AB1234",
  "scheme_code": "BS38OX-DP",
  "amount": 5000,
  "frequency": "monthly",
  "txn_day": 15,
  "installments": 24,
  "first_order_today": true,
  "mandate_id": "BSEM202401150002"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `client_code` | string | Yes (or `ucc_id`) | From UCC wizard |
| `ucc_id` | UUID string | Yes (or `client_code`) | From UCC wizard |
| `scheme_code` | string | Yes | BSE scheme code |
| `amount` | number | Yes | Per-instalment amount in ₹ |
| `frequency` | string | No | `"monthly"` / `"quarterly"` / `"weekly"` / `"daily"` — default: `"monthly"` |
| `txn_day` | int (1–28) | No | Day of month for recurring debits — default: 5 |
| `installments` | int | No | Number of instalments — default: 12 |
| `first_order_today` | boolean | No | `true` = take first payment now (default) |
| `mandate_id` | string | Yes | `mandate_id` from approved mandate |
| `is_fresh` | boolean | No | `true` = new folio — default: `true` |
| `folio_number` | string | No | If `is_fresh: false` |

**Response (success with first payment)**
```json
{
  "success": true,
  "data": {
    "sxp_id": "202605000026716",
    "first_order_id": "660e9500-f31c-...",
    "client_code": "PM_AB1234",
    "scheme_code": "BS38OX-DP",
    "amount": "5000.00",
    "frequency": "monthly",
    "start_date": "2024-02-15",
    "installments": 24,
    "status": "REGISTERED"
  }
}
```

**Response (success — mandate-only, no first payment)**
```json
{
  "success": true,
  "data": {
    "sxp_id": "202605000026717",
    "first_order_id": null,
    "client_code": "PM_AB1234",
    "status": "REGISTERED"
  }
}
```

| Field | Meaning |
|---|---|
| `sxp_id` | BSE SIP registration ID |
| `first_order_id` | UUID of the first-instalment order — present when `first_order_today: true`. Use this as the `order_id` for Step 10. |

**If `first_order_id` is present** → go to Step 10 (take first payment).
**If `first_order_id` is null** → SIP registered, show success, no payment needed now.

---

### Step 10 — Initiate first instalment payment

The first payment uses the same lumpsum payment API (not the SIP payment API) because BSE creates a regular purchase order for it.

```
POST /api/v1/orders/payment/
```

**Request (UPI)**
```json
{
  "order_id": "660e9500-f31c-...",
  "payment_mode": "UPI",
  "upi_id": "user@okaxis"
}
```

**Request (Netbanking)**
```json
{
  "order_id": "660e9500-f31c-...",
  "payment_mode": "NETBANKING"
}
```

`order_id` = the `first_order_id` from Step 9.

**Response (UPI)**
```json
{
  "success": true,
  "message": "Please open your UPI app and complete the payment.",
  "data": {
    "payment_mode": "upi",
    "order_id": "660e9500-f31c-...",
    "bse_payment_ref_id": "BSE2024011500003"
  }
}
```

**Response (Netbanking)**
```json
{
  "success": true,
  "message": "Proceed to Netbanking URL.",
  "data": {
    "payment_mode": "netbanking",
    "order_id": "660e9500-f31c-...",
    "bse_payment_ref_id": "BSE2024011500004",
    "payment_url": "https://pg.bsestarmf.in/pay?ref=...",
    "payment_method": "POST",
    "payment_params": {
      "MerchantCode": "...",
      "TransactionID": "..."
    }
  }
}
```

---

### Step 11 — Poll first payment status

Poll every `poll_interval_seconds` until confirmed or `max_wait_seconds` elapses.

```
GET /api/v1/orders/payment-status/<first_order_id>/
```

**Response**
```json
{
  "success": true,
  "data": {
    "payment_status": "AGENCY_PAYMENT_DONE",
    "order_status": "Payment Received",
    "bse_order_id": "5000305005",
    "internal_order_id": "660e9500-f31c-..."
  }
}
```

**Payment is confirmed when `payment_status` contains any of:**
- `SUCCESS`
- `COMPLETE`
- `AGENCY_PAYMENT`
- or `order_status` contains `PAID`, `SUCCESS`, or `SETTLED`

→ Show the **Success** screen.

---

## Success Screen Data

| Label | Source |
|---|---|
| Type | "SIP — Monthly / Quarterly / etc." |
| Amount | Per-instalment `amount` (from wizard input) |
| Frequency | `frequency` field |
| SIP Date | `txn_day` — "15th of every month" |
| Installments | `installments` |
| BSE SIP ID | `sxp_id` (from Step 9) |
| BSE Order ID | `bse_order_id` (from Step 11) |
| Payment | `payment_status` (from Step 11) |

**Footer message:** "Your first instalment has been debited. Future instalments will auto-debit on the {txn_day}th via your approved mandate — no action needed."

---

## SIP Order History

```
GET /api/v2/orders/?side=sip
```

**Response**
```json
{
  "success": true,
  "data": {
    "sip_orders": [
      {
        "id": "770f0600-a42d-...",
        "sxp_id": "202605000026716",
        "status": "ACTIVE",
        "bse_status": "REGISTERED",
        "sip_amount": "5000.00",
        "sip_frequency": "monthly",
        "sip_start_date": "2024-02-15",
        "sip_end_date": "2026-01-15",
        "total_installments": 24,
        "current_installment": 1,
        "scheme": {
          "id": 14,
          "name": "Aditya Birla Sun Life Credit Risk Fund - IDCW Direct",
          "isin": "INF209KA1K96",
          "amc": "Aditya Birla Sun Life AMC Limited"
        },
        "client_code": "PM_AB1234",
        "next_due_date": "2024-02-15",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:35:00Z"
      }
    ],
    "counts": { "buy": 0, "sell": 0, "switch": 0, "sip": 1 }
  }
}
```

---

## Full Flow Diagram

```
Open SIP Wizard
    │
    ├─ GET /api/v2/trade/payment-poll-config/          ← fetch timer config
    │
    ├─ UCC wizard (same as order.md Steps 1–3)
    │       └─ result: ucc_id + client_code
    │
    ├─ User enters: amount, frequency, txn_day, installments
    │
    ├─ GET /api/v2/trade/mandate/status/
    │       │
    │       ├─ pending mandate exists → go to Authorize (Step 7)
    │       └─ no pending mandate → show Register form (Step 6)
    │
    ├─ POST /api/v2/trade/mandate/register/
    │       └─ returns: mandate_id + authorization_url
    │
    ├─ User authorises at bank
    │   ├─ UPI → approve in UPI app (no URL to open)
    │   └─ eNACH → open authorization_url in new tab
    │
    ├─ GET /api/v2/trade/mandate/poll/?mandate_id=...  ← every 5s, up to 10 min
    │       └─ status: APPROVED
    │
    ├─ POST /api/v2/trade/sip/create/
    │       └─ returns: sxp_id + first_order_id
    │
    ├─ POST /api/v1/orders/payment/                    ← first instalment payment
    │       └─ UPI or Netbanking
    │
    ├─ GET /api/v1/orders/payment-status/<first_order_id>/
    │       └─ poll every 30s, up to 5 min
    │           └─ confirmed → Success Screen
    │
    └─ Show: SIP Started Successfully!
```

---

## Mandate Type Reference

| Type | Auth method | How user approves | Auth URL needed |
|---|---|---|---|
| `"U"` | UPI Autopay | Approve in UPI app | No — BSE sends collect to VPA |
| `"N"` | eNACH | Netbanking / debit card at bank | Yes — open `authorization_url` |
| `"X"` | NACH physical | Physical form submission | No |

---

## Error Handling Reference

| HTTP Status | Error code | Meaning | Action |
|---|---|---|---|
| 400 | — | Missing fields / BSE rejection | Show `message` to user |
| 400 | — | Mandate not yet APPROVED | Wait and retry |
| 404 | — | UCC / bank / mandate not found | Check `client_code` or restart |
| 503 | `BSE_AUTH_FAILED` | BSE broker token expired | Show retry message, contact admin |

---

## Important Notes for Frontend

1. **Always create a new mandate per SIP** — do not reuse the `usable_mandate` from the status endpoint. Each SIP is independent and should have its own mandate.
2. **`first_order_id` is a regular order UUID** — use `/api/v1/orders/payment/` and `/api/v1/orders/payment-status/` for it, not SIP-specific endpoints.
3. **Mandate poll interval is 5 seconds** (hardcoded); payment poll interval comes from the server (`poll_interval_seconds`).
4. **UPI Autopay only**: The `upi_id` (VPA) field is required. Validate it contains `@` before submitting.
5. **`txn_day` must be 1–28** — BSE does not allow 29, 30, 31 to handle February. Backend clamps it automatically.
6. **30-day gap rule**: BSE enforces a minimum 30 days between the first payment today and the first recurring debit on `txn_day`. If the date is too close, BSE will skip one cycle automatically — inform the user.
7. **`suggested_cap`** = 24× the SIP amount, capped at ₹10 lakh, rounded up to nearest ₹500. Recommend this as the default mandate limit so future SIP top-ups don't require a new mandate.
