# MF Central Portfolio & Transactions API (v2)

This document details the newly added endpoints under `apiv2` that provide Mutual Fund holdings and transaction data mapped to the frontend UI's expected schemas.

## 1. User MF Holdings API

Retrieves the current mutual fund holdings/folio details for the authenticated user, sourced from MF Central CAS payloads.

**Endpoint:** `/api/v2/portfolio/user-holdings/`  
**Method:** `GET`  
**Authentication:** JWT Bearer Token (`Authorization: Bearer <token>`)

### Request Payload
*None required. Data is scoped to the authenticated user.*

### Response Payload

```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "createdat": "2024-05-01T10:00:00Z",
      "userguid": "1",
      "logo": null,
      "activestate": true,
      "reqid": "",
      "amc": "101",
      "amcname": "HDFC Mutual Fund",
      "taxstatus": "Resident Individual",
      "modeofholding": "Single",
      "transactionsource": "BSE",
      "schemecode": "HDFC01",
      "name": "HDFC Mid-Cap Opportunities Fund",
      "idcwchangeallowed": false,
      "schemeoption": "Growth",
      "assettype": "Equity",
      "schemetype": "Open Ended",
      "nav": 150.25,
      "navdate": "2024-05-04",
      "closingbalance": 100.5,
      "isdemat": false,
      "currentmktvalue": 15100.12,
      "costvalue": 14000.00,
      "gainloss": 1100.12,
      "gainlosspercentage": 7.85,
      "lienunitsflag": false,
      "decimalunits": 3,
      "decimalamount": 2,
      "decimalnav": 4,
      "brokercode": "ARN-1234",
      "brokername": "",
      "purallow": true,
      "redallow": true,
      "swtallow": true,
      "sipallow": true,
      "stpallow": true,
      "swpallow": true,
      "planmode": "Direct",
      "dpid": "",
      "mobilerelationship": "Self",
      "emailrelationship": "Self",
      "newfolio": false,
      "nomineestatus": "Registered",
      "lienavailableunits": 0.0,
      "investorname": "John Doe",
      "guid": "123",
      "quantity": 100.5,
      "rtacode": "CAMS",
      "lasttrxndate": null,
      "openingbal": 0.0,
      "folio": "1234567890",
      "age": "",
      "phonenumber": "9876543210",
      "email": "john@example.com",
      "availableunits": 100.5,
      "availableamount": 0.0,
      "isin": "INF179K01YE8",
      "validpan": true,
      "kycstatus": "Verified",
      "lieneligibleunits": 0.0,
      "bankaccnumber": "",
      "bankacctype": "Savings",
      "bankaccname": "",
      "bankbranch": "",
      "bankcity": "",
      "bankpincode": "",
      "bankmicr": "",
      "bankifsc": "",
      "bankneftifsc": "",
      "rtaname": "CAMS",
      "foliocreateddate": "2024-05-01T10:00:00Z",
      "mfsummaryguid": "",
      "fatcastatus": "",
      "amficode": "",
      "isindescription": "",
      "lockinunits": 0.0,
      "registrar": "CAMS",
      "schemecategory": "",
      "schemetypes": "Open Ended",
      "ucc": "",
      "fipname": "",
      "fipid": "",
      "linkrefnumber": "",
      "maskeddemataccount": "",
      "xirrvalue": 0.0,
      "cagrvalue": 0.0,
      "closingunits": 100.5,
      "lienunits": 0.0,
      "accountguid": "",
      "investoremail": "john@example.com",
      "investorphonenumber": "9876543210",
      "investoraddress": "",
      "investordataguid": "",
      "deltavalue": 0.0,
      "delta": 0.0,
      "holdingavgprice": 0.0,
      "deltapercentage": 0.0,
      "swapamount": 0.0,
      "frequency": "",
      "installments": "",
      "nextinstallments": "",
      "type": "",
      "lasttransactiondate": null,
      "count": 0
    }
  ]
}
```

### Field Mappings & Dummy Values
| Field Status | Examples | Description |
|---|---|---|
| **Live Data** | `nav`, `isin`, `name`, `folio`, `quantity`, `currentmktvalue`, `phonenumber`, `email`, `amc`, `taxstatus` | Pulled directly from `MfCentralHolding` & `MfCentralFolio`. |
| **Empty / Dummy Defaults** | `logo`, `xirrvalue`, `cagrvalue`, `bankaccnumber`, `bankifsc`, `fipid`, `age`, `dpid` | Not natively stored in Django models or computed real-time. Sent as `""`, `0.0`, `null`, or `False` to preserve frontend schema requirements. |

---

## 2. User MF Transactions API

Retrieves the transaction history for all mutual funds held by the authenticated user.

**Endpoint:** `/api/v2/portfolio/user-transactions/`  
**Method:** `GET`  
**Authentication:** JWT Bearer Token (`Authorization: Bearer <token>`)

### Request Payload
*None required. Data is scoped to the authenticated user.*

### Response Payload

```json
{
  "success": true,
  "data": [
    {
      "category": "",
      "date": "2024-05-02",
      "quantity": 50.25,
      "avgBuyPrice": 140.50,
      "investedValue": 7060.12,
      "currentMarketPrice": 0.0,
      "currentValue": 0.0,
      "exchange": 0.0,
      "name": "HDFC Mid-Cap Opportunities Fund",
      "type": "SIP Purchase",
      "daysGainValue": 0.0,
      "daysGainPercent": 0.0,
      "totalGainValue": 0.0,
      "totalGainPercent": 0.0,
      "xirrPercent": 0.0,
      "ltcgValue": 0.0,
      "stcgValue": 0.0,
      "txnamount": 7060.12,
      "image_url": "",
      "description": "Auto SIP via BillDesk",
      "folio_no": "1234567890",
      "brokercode": "ARN-1234",
      "registrar": "CAMS",
      "brokername": "",
      "isin": "INF179K01YE8"
    }
  ]
}
```

### Field Mappings & Dummy Values
| Field Status | Examples | Description |
|---|---|---|
| **Live Data** | `date`, `quantity`, `avgBuyPrice` (nav), `investedValue`, `name`, `type`, `folio_no`, `brokercode`, `isin`, `description` | Pulled directly from `MfTransaction` model. |
| **Empty / Dummy Defaults** | `category`, `currentMarketPrice`, `xirrPercent`, `ltcgValue`, `stcgValue`, `image_url` | Not natively stored in `MfTransaction`. Set to `""` or `0.0` to preserve the schema for the UI. |
