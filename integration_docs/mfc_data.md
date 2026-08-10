# MF Data & Structured Insights API

These endpoints provide structured data for building the portfolio, transaction history, and unified SIP views on the frontend. They integrate data from both BSE (Star MF) and external sources (CAS/MF Central).

## Authentication
All endpoints require a valid JWT token in the `Authorization: Bearer <token>` header.

---

## 1. Portfolio Summary
Returns a high-level summary of holdings, including current valuation, cost, and a list of specific holdings.

- **URL**: `/api/v1/mf/data/portfolio/`
- **Method**: `GET`
- **Success Response (200 OK)**:
```json
{
  "holding_count": 5,
  "total_current_value": "150000.00",
  "total_cost_value": "120000.00",
  "latest_snapshot": {
    "as_of": "2026-04-15",
    "total_value": 150000.00,
    "breakdown": { "Equity": 80, "Debt": 20 }
  },
  "holdings": [
    {
      "id": 1,
      "folio_number": "12345678",
      "amc_name": "HDFC Mutual Fund",
      "isin": "INF179K01BY2",
      "scheme_name": "HDFC Top 100 Fund",
      "units": "500.000",
      "nav": "300.00",
      "current_value": "150000.00",
      "cost_value": "120000.00"
    }
  ]
}
```

---

## 2. Transaction History
Returns a paginated list of all mutual fund transactions (Purchases, Redemptions, Dividends, etc.) across all folios.

- **URL**: `/api/v1/mf/data/transactions/`
- **Method**: `GET`
- **Parameters**:
  - `limit` (optional, default: 50, max: 200)
  - `offset` (optional, default: 0)
- **Success Response (200 OK)**:
```json
{
  "count": 12,
  "results": [
    {
      "id": 101,
      "txn_type": "Purchase",
      "trade_date": "2026-04-10T00:00:00",
      "amount": "10000.00",
      "units": "33.333",
      "source": "BSE",
      "folio_id": 5
    }
  ]
}
```

---

## 3. Unified SIPs
Returns a combined list of active SIPs registered via BSE and those detected from external CAS/MF Central imports.

- **URL**: `/api/v1/mf/data/sips/`
- **Method**: `GET`
- **Success Response (200 OK)**:
```json
{
  "bse_sips": [
    {
      "origin": "BSE",
      "id": 20,
      "scheme_code": "HDFC123",
      "amount": "5000.00",
      "frequency": "Monthly",
      "status": "APPROVED",
      "start_date": "2026-05-01"
    }
  ],
  "external_sips": [
    {
      "origin": "CAS_OR_AA",
      "id": 5,
      "folio_number": "91028374",
      "amount": "2000.00",
      "frequency": "Weekly",
      "status": "ACTIVE",
      "source": "MFCentral"
    }
  ]
}
```

---

## 4. Capital Gains
Returns capital gains data for a specific financial year or all records.

- **URL**: `/api/v1/mf/data/capital-gains/`
- **Method**: `GET`
- **Parameters**:
  - `fy` (optional, e.g., `2025-2026`)
- **Success Response (200 OK)**:
```json
{
  "results": [
    {
      "id": 1,
      "fy": "2025-2026",
      "gain_type": "LTCG",
      "sale_proceeds": "50000.00",
      "purchase_cost": "40000.00",
      "source": "CAS_Import"
    }
  ]
}
```
