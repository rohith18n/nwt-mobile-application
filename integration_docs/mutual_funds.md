# Mutual funds API — request & response payloads

All paths below are mounted under your server’s **`/api/v1/`** prefix (see `pivotmoney_backend/urls.py`).

**Authentication:** every endpoint in this document requires a valid JWT **access** token.

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

Each route accepts **GET** (query string) or **POST** (JSON body) with the same parameter names unless noted.

**There is no `client_code` / UCC parameter.** Eligibility comes only from the **JWT user** profile.

---

## How eligibility works (JWT user only)

1. **Base universe** — Direct, OPEN, active investment mode schemes (`_base_investable_qs` in `user.beta_mf_views`).

2. **Lumpsum investable** — Each row is checked with **`MutualFundValidator`** (RIA direct-only, effective dates, purchase rules).

3. **Physical mode** — `SchemeService.scheme_matches_phys_or_demat(scheme, is_demat=False)`. Profile-based browsing assumes **physical** purchase (no UCC to read demat flag). Schemes that only allow demat in our data are **excluded** from list/search and blocked on detail.

4. **Country + residency → AMC whitelist** — `bse_mf.holding_filters.investor_category_from_user(user)` derives a category string stored in **`AMCCompatibility`**:

   | User signals | Typical category |
   |--------------|------------------|
   | `investor_residency` is **Resident** and `ucc_profile.country` is empty or India (`IN` / `IND` / `INDIA`) | **`RESIDENT`** → no AMC whitelist (all AMCs allowed subject to steps 1–3). |
   | `investor_residency` is **`NRI-NRE`** or **`NRI-NRO`**, or `ucc_profile.country` is a **non-India** ISO-style code | **NRI**; country maps to **`NRI_USA`**, **`NRI_CANADA`**, or **`NRI_OTHER`**. Unknown country uses the same fallback as UCC flows (`NRI_OTHER` → Canada-compatible list if empty). |
   | Canada (`CA` / `CAN`) | **`NRI_CANADA`** — **fewer** funds than a resident Indian. |

5. **`scheme_allowed_for_app_user(scheme, user)`** — Ensures the scheme’s AMC is allowed for that category with **SI** holding (same tables as UCC-based browse, without an `InvestorUCC` row).

**Frontend should keep `ucc_profile.country` and `investor_residency` accurate** (e.g. via profile APIs) so list/search/detail match what the user can actually buy.

Responses include **`investor_category`** (the derived category string) so you can debug or display eligibility context.

---

## 1. `GET` / `POST` `/api/v1/mutual_funds/list/`

**Purpose:** Paginated **browse** of schemes the user may invest in. **No text search**, **no Django `Q`**.

### Request parameters

| Field | Type | Required | Default | Notes |
|--------|------|----------|---------|--------|
| `start` | int | no | `0` | Offset. |
| `length` | int | no | `24` | Page size, **1–200**. |
| `include_total` | bool | no | `false` | If `true`, full scan for **`total_count`** (slower). |

### Response `200`

```json
{
  "success": true,
  "data": {
    "start": 0,
    "length": 24,
    "has_more": true,
    "investor_category": "RESIDENT",
    "total_count": 1234,
    "schemes": [
      {
        "scheme_isin": "INF209K01XX0",
        "scheme_name": "Example Direct Growth",
        "minimum_amount": 500.0,
        "scheme_code": "ABC123-DG"
      }
    ]
  }
}
```

- **`total_count`** only if **`include_total`** was true.
- **`minimum_amount`** = `lumpsum_limits["min"]`.

---

## 2. `GET` / `POST` `/api/v1/mutual_funds/search/`

**Purpose:** **Typeahead** while the user types (e.g. 4, 5, 6+ characters). Uses **`django.db.models.Q`**: case-insensitive **`OR`** on **name**, **scheme_code**, **ISIN**, **AMC name**. Returns only the **first 6–8** matching investable schemes (same user filters as **list**), not a large page.

### Request parameters

| Field | Type | Required | Default | Notes |
|--------|------|----------|---------|--------|
| **`q`** or **`query`** | string | **yes** | — | Trimmed. Empty → **400**. |
| | | | | Must be at least **2** characters (config: `_MF_SEARCH_QUERY_MIN_LEN`). Use **4+** in the UI for lighter load. |
| `limit` | int | no | `8` | Clamped to **6–8** only. |

### Response `200`

```json
{
  "success": true,
  "data": {
    "q": "hdfc",
    "limit": 8,
    "count": 6,
    "investor_category": "NRI_CANADA",
    "schemes": [
      {
        "scheme_isin": "INF179K01XY2",
        "scheme_name": "…",
        "minimum_amount": 100.0,
        "scheme_code": "…"
      }
    ]
  }
}
```

- **`count`** = number of rows returned (≤ `limit`). There is **no** `has_more` / `total_count`; call again when `q` changes.

### Errors

| HTTP | When |
|------|------|
| **400** | Missing **`q`**, or shorter than minimum length. |

---

## 3. `GET` / `POST` `/api/v1/mutual_funds/detail/`

**Purpose:** One scheme’s shareable BSE-backed payload by **ISIN**. Lookup: **`scheme_isin__iexact`** (no **`Q`**).

### Request parameters

| Field | Type | Required | Notes |
|--------|------|----------|--------|
| **`isin`** or **`scheme_isin`** | string | **yes** | |

### Processing

1. Load by ISIN → **404** if missing.
2. Physical-mode check → **400** if scheme does not allow physical in our data.
3. **`scheme_allowed_for_app_user`** → **400** if AMC not allowed for user profile.
4. **`MutualFundValidator`** → **400** if not investable / lumpsum not allowed (`data.validation`).
5. Build detail dict + **`investor_category`** + **`validation_summary`**.

### Response `200` (overview)

- Model fields (except internal **`data_hash`**), **`lumpsum_limits`**, **`sip_limits`**, related rule arrays, **`investor_category`**, **`validation_summary`**.

### Errors

| HTTP | When |
|------|------|
| **400** | Missing ISIN; physical mode; AMC policy; or not open for lumpsum. |
| **404** | Unknown ISIN. |

---

## 4. Implementation map

| Concern | Location |
|---------|----------|
| URL routes | `pivotmoney_backend/apiv1/urls.py` |
| List / search / detail + DRF bridge re-exported via `http` | `pivotmoney_backend/apiv1/views/mutual_funds.py` |
| User → category, AMC allowlist without UCC | `pivotmoney_backend/bse_mf/holding_filters.py` (`investor_category_from_user`, `scheme_allowed_for_app_user`, `get_allowed_amc_codes_and_names_for_category`) |
| Physical/demat check | `pivotmoney_backend/bse_mf/services.py` (`SchemeService.scheme_matches_phys_or_demat`) |
| Base queryset | `pivotmoney_backend/user/beta_mf_views.py` (`_base_investable_qs`, `_count_lumpsum_investable`) |
| Validator | `pivotmoney_backend/bse_mf/validators.py` |

---

## 5. Quick comparison

| Endpoint | `Q` search? | Result size |
|----------|-------------|-------------|
| **`mutual_funds/list/`** | No | Paginated (`start` / `length`). |
| **`mutual_funds/search/`** | Yes | Fixed **6–8** rows (`limit`). |
| **`mutual_funds/detail/`** | No (exact ISIN) | Single scheme. |

All three use the **same JWT user** eligibility (country + residency + physical mode + validator).
