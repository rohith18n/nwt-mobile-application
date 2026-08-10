# Lumpsum Order Flow — Frontend Integration Guide

## Overview

A lumpsum (one-time purchase) order goes through three phases:

```
UCC Setup → Create Order → Initiate Payment → Poll for Confirmation → Success
```

The UCC (Unique Client Code) is your BSE investor account. Before placing any order you must have a valid UCC with `investment_ready: true`. The UCC wizard (steps 1–4 below) handles this automatically by checking for an existing active UCC first.

---

## Base URL

All apiv2 endpoints: `/api/v2/`
All apiv1 (order/payment) endpoints: `/api/v1/`

Authentication: `Authorization: Bearer <access_token>` on every request.

---

## Complete Step-by-Step Flow

### Step 0 — Fetch poll configuration (once on wizard open)

Used to drive the countdown timer on the payment-polling screen.

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

---

### Step 1 — Resolve existing UCC

Call this after the user selects their holding type (SI or AS) and nomination choice. The backend checks if a matching UCC already exists and is active — if so, you skip straight to the amount entry step.

```
POST /api/v2/trade/ucc/resolve/
```

**Request**
```json
{
  "holding_nature": "SI",
  "nomination": "skip"
}
```

```json
{
  "holding_nature": "AS",
  "secondary_holder_id": 12,
  "nomination": "provide",
  "nominee_holder_id": 7
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `holding_nature` | `"SI"` \| `"AS"` | Yes | SI = single holder, AS = joint |
| `secondary_holder_id` | int | If AS | UserHolder PK of the joint holder |
| `nomination` | `"provide"` \| `"skip"` | No | Defaults to skip |
| `nominee_holder_id` | int | If provide | UserHolder PK of the nominee |

**Response — UCC found and active**
```json
{
  "success": true,
  "data": {
    "exists": true,
    "holding_nature": "SI",
    "ucc_id": "a1b2c3d4-...",
    "client_code": "PM_AB1234",
    "investment_ready": true,
    "beta_stage": "bse_wizard_complete",
    "payment_upi_id": "user@okaxis"
  }
}
```

**Response — No existing UCC**
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

**Frontend logic:**
- `investment_ready === true` → store `ucc_id` + `client_code`, go to **Amount** step
- `exists === true` but not ready → continue with onboarding steps below
- `exists === false` → create a draft (Step 2)

---

### Step 2 — Create UCC draft (only if no existing UCC)

```
POST /api/v2/trade/ucc/draft/
```

**Request (single holder)**
```json
{ "holding_nature": "SI" }
```

**Request (joint)**
```json
{
  "holding_nature": "AS",
  "secondary_holder_id": 12
}
```

**Response**
```json
{
  "success": true,
  "data": {
    "reused": false,
    "holding_nature": "SI",
    "investment_ready": false,
    "client_code": "PM_AB1234",
    "beta_stage": "awaiting_nomination",
    "payment_upi_id": "user@okaxis"
  }
}
```

If `reused === true` and `ucc_id` is present → go straight to **Amount** step.

---

### Step 3 — Submit nomination choice

```
POST /api/v2/trade/ucc/nomination/
```

**Request — opt-out (no nominee)**
```json
{
  "client_code": "PM_AB1234",
  "choice": "skip"
}
```

**Response (opt-out)**
```json
{
  "success": true,
  "data": {
    "client_code": "PM_AB1234",
    "next_action": "verify_opt_out_otp",
    "delivery": {
      "email_sent": true,
      "email_masked": "u***@gmail.com"
    }
  }
}
```
→ Show OTP entry screen. Email was sent to the registered address.

---

**Request — provide nominee**
```json
{
  "client_code": "PM_AB1234",
  "choice": "provide",
  "nominee_holder_id": 7
}
```

**Response (provide — BSE auto-submitted)**
```json
{
  "success": true,
  "data": {
    "client_code": "PM_AB1234",
    "next_action": "bse_finished",
    "bse_finished": true,
    "ucc_id": "a1b2c3d4-..."
  }
}
```
→ Backend auto-submits to BSE. If `bse_finished === true`, store `ucc_id` and go to **Amount** step — no manual OTP needed.

If `bse_finished` is absent, fall through to BSE OTP entry.

---

### Step 3a — Opt-out OTP verification

```
POST /api/v2/trade/ucc/nominee-opt-out/verify/
```

**Request**
```json
{
  "client_code": "PM_AB1234",
  "otp": "847291"
}
```

**Response**
```json
{
  "success": true,
  "data": {
    "client_code": "PM_AB1234",
    "ucc_id": "a1b2c3d4-...",
    "bse_finished": true
  }
}
```
→ Store `ucc_id`, go to **Amount** step.

**Resend OTP:**
```
POST /api/v2/trade/ucc/nominee-opt-out/resend/
{ "client_code": "PM_AB1234" }
```

---

### Step 3b — BSE OTP (provide-nominee path only, rare)

Only shown if the nomination response did NOT include `bse_finished: true`.

```
POST /api/v2/trade/ucc/bse/finish/
```

**Request**
```json
{
  "client_code": "PM_AB1234",
  "otp": "572813"
}
```

**Response**
```json
{
  "success": true,
  "data": {
    "ucc_id": "a1b2c3d4-...",
    "client_code": "PM_AB1234"
  }
}
```
→ Store `ucc_id`, go to **Amount** step.

---

### Step 4 — Create the lumpsum order

```
POST /api/v1/orders/create/
```

**Request**
```json
{
  "ucc_id": "a1b2c3d4-...",
  "scheme_code": "BS38OX-DP",
  "amount": 5000,
  "mode": "Physical",
  "is_fresh": true
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `ucc_id` | UUID string | Yes | From UCC wizard |
| `scheme_code` | string | Yes | BSE scheme code shown on detail page |
| `amount` | number | Yes | In rupees |
| `mode` | `"Physical"` | Yes | Always use `"Physical"` |
| `is_fresh` | boolean | No | `true` = new folio, `false` = add to existing |
| `folio_number` | string | No | If `is_fresh = false` |

**Response (success)**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "order_id": "550e8400-e29b-...",
    "bse_order_id": "5000304891",
    "amount": "5000.00",
    "bank_details": [
      {
        "bank_name": "HDFC Bank",
        "account_number": "50100123456789",
        "ifsc_code": "HDFC0001234"
      }
    ],
    "upi_id": "user@okaxis"
  }
}
```

**Response (error — not investment-ready)**
```json
{
  "success": false,
  "message": "This account is not yet active for investments. Your UCC is being processed by BSE — please try again in a few minutes."
}
```

**Response (error — amount limit)**
```json
{
  "success": false,
  "message": "Order failed. Allowed: minimum ₹1000, maximum ₹500000, in multiples of ₹1.",
  "details": {
    "limits": {
      "min_amount": "1000",
      "max_amount": "500000",
      "multiple": "1"
    }
  }
}
```

Store `order_id` — needed for payment and status polling.

---

### Step 5 — Initiate payment

```
POST /api/v1/orders/payment/
```

**Request (UPI)**
```json
{
  "order_id": "550e8400-e29b-...",
  "payment_mode": "UPI",
  "upi_id": "user@okaxis"
}
```

**Request (Netbanking)**
```json
{
  "order_id": "550e8400-e29b-...",
  "payment_mode": "NETBANKING"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `order_id` | UUID string | Yes | From Step 4 |
| `payment_mode` | `"UPI"` \| `"NETBANKING"` | Yes | Case-insensitive |
| `upi_id` | string | If UPI | e.g. `name@okaxis` |

**Response (UPI)**
```json
{
  "success": true,
  "message": "Please open your UPI app and complete the payment.",
  "data": {
    "payment_mode": "upi",
    "order_id": "550e8400-e29b-...",
    "bse_payment_ref_id": "BSE2024011500001"
  }
}
```
→ Show countdown timer. User completes payment in their UPI app. Start polling.

**Response (Netbanking)**
```json
{
  "success": true,
  "message": "Proceed to Netbanking URL.",
  "data": {
    "payment_mode": "netbanking",
    "order_id": "550e8400-e29b-...",
    "bse_payment_ref_id": "BSE2024011500002",
    "payment_url": "https://pg.bsestarmf.in/pay?ref=...",
    "payment_method": "POST",
    "payment_params": {
      "MerchantCode": "...",
      "TransactionID": "..."
    }
  }
}
```
→ Open `payment_url` in a new tab. If `payment_method === "POST"` submit a form with `payment_params` to `payment_url`.

---

### Step 6 — Poll payment status

Poll every `poll_interval_seconds` (from Step 0) until `max_wait_seconds` elapses.

```
GET /api/v1/orders/payment-status/<order_id>/
```

`order_id` can be either the internal UUID or the BSE order ID from Step 4.

**Response**
```json
{
  "success": true,
  "data": {
    "payment_status": "AGENCY_PAYMENT_DONE",
    "order_status": "Payment Received",
    "bse_order_id": "5000304891",
    "internal_order_id": "550e8400-e29b-..."
  }
}
```

**Payment is confirmed when `payment_status` contains any of:**
- `SUCCESS`
- `COMPLETE`
- `AGENCY_PAYMENT`
- or `order_status` contains `PAID`, `SUCCESS`, or `SETTLED`

→ Show the **Success** screen (see below).

If `max_wait_seconds` elapses with no confirmation, show an error with a retry option.

---

## Success Screen Data

Display after confirmed payment. All fields come from the Step 4 + Step 6 responses.

| Label | Source |
|---|---|
| Type | "Lumpsum Purchase" |
| Amount | `order.amount` (from Step 4) |
| BSE Order ID | `data.bse_order_id` (from Step 4 or 6) |
| Reference ID | `data.internal_order_id` (from Step 6) |
| Payment Status | `data.payment_status` (from Step 6) |
| Order Status | `data.order_status` (from Step 6) |

---

## Order History

```
GET /api/v2/orders/?side=buy
```

**Query params:** `side = buy | sell | switch | sip` (omit for all)

**Response**
```json
{
  "success": true,
  "data": {
    "buy_orders": [
      {
        "id": "550e8400-e29b-...",
        "side": "Buy",
        "type_code": "P",
        "status": "SUCCESS",
        "ui_status": "Payment Received",
        "bse_order_id": "5000304891",
        "bse_order_status": "OT",
        "bse_remark": "",
        "amount": "5000.00",
        "scheme": {
          "id": 14,
          "name": "Aditya Birla Sun Life Credit Risk Fund - IDCW Direct",
          "isin": "INF209KA1K96",
          "amc": "Aditya Birla Sun Life AMC Limited"
        },
        "client_code": "PM_AB1234",
        "folio_number": null,
        "placed_at": "2024-01-15T10:30:00Z",
        "payment_ref_no": "BSE2024011500001",
        "allotment_date": null,
        "allotment_units": null,
        "allotment_price": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:35:00Z"
      }
    ],
    "sell_orders": [],
    "switch_orders": [],
    "sip_orders": [],
    "counts": { "buy": 1, "sell": 0, "switch": 0, "sip": 0 }
  }
}
```

---

## Full Flow Diagram

```
Open Wizard
    │
    ├─ GET /api/v2/trade/payment-poll-config/       ← fetch timer config
    │
    ├─ User selects: holding type (SI/AS) + nominee choice
    │
    ├─ POST /api/v2/trade/ucc/resolve/
    │       │
    │       ├─ investment_ready: true  ──────────────────────────────┐
    │       │                                                         │
    │       └─ exists: false                                          │
    │               │                                                 │
    │           POST /api/v2/trade/ucc/draft/                        │
    │               │                                                 │
    │           POST /api/v2/trade/ucc/nomination/                   │
    │               │                                                 │
    │               ├─ choice: skip → optout_otp screen              │
    │               │   POST /api/v2/trade/ucc/nominee-opt-out/      │
    │               │         verify/                                 │
    │               │                                                 │
    │               └─ choice: provide → bse_finished: true ─────────┤
    │                   (or BSE OTP screen if not auto-finished)      │
    │                                                                 ▼
    │                                               Enter amount ─────┤
    │                                                                 │
    │                                           POST /api/v1/orders/create/
    │                                                                 │
    │                                           POST /api/v1/orders/payment/
    │                                                                 │
    │                                       ┌── GET /api/v1/orders/payment-status/<id>/
    │                                       │   (poll every 30s, up to 5 min)
    │                                       │
    │                                       └── confirmed → Success Screen
    │
    └─ User sees: Order Placed Successfully
```

---

## Error Handling Reference

| HTTP Status | Meaning | Action |
|---|---|---|
| 400 | Validation error / BSE rejection | Show `message` to user |
| 404 | UCC or scheme not found | Restart wizard |
| 503 | BSE login unavailable (`error_code: "BSE_AUTH_FAILED"`) | Show retry message, contact admin |

---

## Important Notes for Frontend

1. **Always use `mode: "Physical"`** — Demat mode is not supported.
2. **`order_id` is a UUID** — use it consistently between Steps 4, 5, and 6.
3. **Poll interval and max wait come from the server** (Step 0) — do not hard-code them.
4. **UPI flow**: After initiating payment, BSE pushes a collect request to the user's UPI app. The user approves it there — your UI just needs to poll for confirmation.
5. **Netbanking flow**: If `payment_method === "POST"`, build an HTML form with `action = payment_url` and the fields from `payment_params`, then submit it — a plain redirect link will not work.
6. **Pre-fill UPI ID**: The resolve and nomination responses include `payment_upi_id` — use it to pre-populate the UPI field so the user doesn't have to type it again.
