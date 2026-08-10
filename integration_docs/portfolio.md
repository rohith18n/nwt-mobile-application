# Portfolio API Integration Instructions

This document outlines the REST APIs for retrieving user investment history (Lumpsum and SIP).

All APIs require standard JWT Authentication via the `Authorization: Bearer <token>` header.

---

## 1. List Mutual Fund Orders (Lumpsum)
Retrieve a paginated list of all Mutual Fund orders placed by the user.

**Endpoint:** `GET /api/v1/portfolio/mutual_funds/list/`

**Query Parameters (Optional):**
- `page`: Page number (default: 1)
- `page_size`: Results per page (default: 20)

**Response:**
```json
{
  "count": 100,
  "next": "url-to-next-page",
  "previous": null,
  "results": [
    {
      "id": "order-id",
      "bse_order_id": "BSE123",
      "ui_status": "DONE", // Detailed UI color status (DONE, PROCESSING, FAILED, PAYMENT_PENDING)
      "amount": "1000.00",
      "folio_number": "12345/67", // Available when status is DONE
      "scheme_name": "Axis Bluechip Fund",
      "placed_at": "2024-04-12T10:00:00Z"
      ...
    }
  ]
}
```

## 2. Order Detail (Mutual Fund)
Get detailed lifecycle information for a specific order.

**Endpoint:** `GET /api/v1/portfolio/mutual_funds/<order_id>/`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "order-id",
    "bse_order_id": "BSE123",
    "internal_status": "PLACED",
    "ui_status": "DONE",
    "amount": "1000.00",
    "folio_number": "12345/67",
    "allotment_units": "52.34",
    "allotment_price": "19.10",
    "payment": {
      "payment_status": "SUCCESS",
      "bse_payment_ref_id": "PAY123"
    }
    ...
  }
}
```

## 3. List SIPs
Retrieve a paginated list of all SIP registrations.

**Endpoint:** `GET /api/v1/portfolio/sip/list/`

**Response:** Standard paginated response similar to MF List.

## 4. SIP Detail (Lifecycle)
Get full lifecycle detail for a SIP, including all installments and their statuses.

**Endpoint:** `GET /api/v1/portfolio/sip/<sip_id>/`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "sip-id",
    "sxp_id": "SIP123",
    "scheme_name": "Canara Robeco Bluechip",
    "status": "ACTIVE",
    "total_installments": 12,
    "current_installment": 3,
    "installments": [
      {
        "number": 1,
        "due_date": "2024-01-01",
        "status": "PAID",
        "ui_status": "SUCCESS"
      },
      ...
    ]
  }
}
```
---
**Note:** Use the `ui_status` field to color-code statuses on the frontend (Green for DONE/SUCCESS, Amber for PAYMENT_PENDING/PROCESSING, Red for FAILED).

---

## 5. Portfolio Sellable List
**Endpoint:** `GET /api/v1/portfolio/mutual_funds/sellable/`
**Auth:** Bearer (JWT)

Returns all purchase orders that have a valid folio number and can be redeemed. Returns paginated results.

---

<!-- ## 6. Order Redemption (Sell)
**Endpoint:** `POST /api/v1/order/redeem/`
**Auth:** Bearer (JWT)

Place a redemption order for a specific scheme and folio.

**Request Body:**
```json
{
    "purchase_order_id": 123, // Recommended: ID from the sellable list
    "ucc_id": "uuid-here",    // Optional if purchase_order_id is provided
    "scheme_code": "101AXG",  // Optional if purchase_order_id is provided
    "folio_number": "12345/67", // Optional: will fallback to DB last folio if not provided
    "amount": 5000,           // Amount in INR
    "units": 0,               // OR units to redeem
    "all_units": false        // OR set true to redeem everything
}
```

**Note:** If `purchase_order_id` is passed, the API will automatically fetch the `ucc_id`, `scheme_code`, and `folio_number` from that order record. You can still provide them explicitly to override.

**Response:**
```json
{
    "success": true,
    "message": "Redemption order placed successfully",
    "data": {
        "order_id": 456,
        "bse_order_id": "REDEEM789",
        "amount": "5000.0"
    }
} -->
```
