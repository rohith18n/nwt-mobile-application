# Total Gain & Total Gain % — Backend Implementation

## What was built

Users can now see **total gain** and **total gain %** for their equity/ETF holdings. Since Finarkein (AA) does not provide the actual buy price, we built a feature where users manually enter their average buy price per stock.

**Without user input:** `total_gain` and `total_gain_pct` show `null`  
**After user enters avg buy price:** Real P&L is calculated and shown

## What changed

### New files (2)
| File | Purpose |
|---|---|
| `financial_aggregator/migrations/0016_user_input_buy_price.py` | Migration — creates `UserInputBuyPrice` table |
| `apiv2/views/user_cost.py` | API endpoint to save/remove avg buy price |

### Modified files (5)
| File | Change |
|---|---|
| `financial_aggregator/models.py` | Added `UserInputBuyPrice` model |
| `financial_aggregator/admin.py` | Registered in admin panel |
| `apiv2/urls.py` | Added route for cost endpoint |
| `realtime/portfolio.py` | Added `total_gain` / `total_gain_pct` to WebSocket |
| `apiv2/service/utils/equity_portfolio_service.py` | Added override check in REST portfolio |

## API for frontend

### Save avg buy price
```
PUT /api/v2/portfolio/holdings/cost/
Body: { "isin": "<stock ISIN>", "avg_buy_price": <number> }
```

### Remove override (back to null)
```
DELETE /api/v2/portfolio/holdings/cost/?isin=<stock ISIN>
```

## What frontend needs to build

1. **One editable field per holding card** — user can type their avg buy price
2. **On save** → call `PUT /api/v2/portfolio/holdings/cost/` with the ISIN and price
3. **Refresh portfolio** → `total_gain_loss` and `gain_percent` will show real values
4. **Reset button** → call `DELETE` to clear the override

## WebSocket fields (already live)

In every `portfolio.snapshot` and `portfolio.delta`:
```json
{
  "total_gain": -4.76,
  "total_gain_pct": -0.26,
  "totals": {
    "total_gain": -4.26,
    "total_gain_pct": -0.098
  }
}
```

## REST response fields

`GET /api/v2/portfolio/equity/` already returns:
```json
{
  "total_gain_loss": -4.76,
  "gain_percent": -0.26,
  "portfolio_summary": {
    "total_gain_loss": -4.26,
    "gain_percent": -0.098
  }
}
```
