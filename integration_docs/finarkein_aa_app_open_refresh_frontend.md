# Finarkein AA App-Open Refresh Frontend Guide

This document describes the new once-per-day AA refresh flow that should run when the user opens the app after authentication.

## Purpose

The frontend should no longer decide whether AA data should refresh "once per day".

Instead:

1. Frontend calls one backend endpoint on app open.
2. Backend decides whether data is already fresh, whether a refresh is already running, whether quota should block the refresh, or whether a new refresh should start.
3. Frontend renders UI based on the backend response.

This keeps daily freshness, quota, deduplication, and retry logic on the backend.

## Endpoint Summary

### Start / check app-open refresh

- `POST /api/v1/aa/data/refresh/on-open/`

Used once on app open after user authentication.

### Poll refresh operation status

- `GET /api/v1/aa/data/refresh/on-open/<operation_id>/`

Used only when the `POST` response says polling is needed.

## Backend Response States

### States returned by `POST /aa/data/refresh/on-open/`

- `already_fresh`
- `started`
- `in_progress`
- `skipped_quota`
- `no_consent`
- `failed_recently`
- `completed_with_partial_failures`

### States returned by `GET /aa/data/refresh/on-open/<operation_id>/`

- `in_progress`
- `completed`
- `completed_with_partial_failures`
- `failed`

## Common Response Fields

These fields can be returned by the new app-open refresh endpoints:

| Field | Meaning |
|---|---|
| `state` | Main lifecycle state for app-open refresh. |
| `operationId` | Refresh operation id. Present when an operation exists. |
| `statusUrl` | Poll this URL when the state is `started` or `in_progress`. |
| `pollAfterSeconds` | Suggested polling interval. |
| `lastSuccessfulRefreshAt` | Latest successful refresh time if known. |
| `nextAutoRefreshAfter` | When the next automatic app-open refresh is allowed. |
| `nextRetryAfter` | Backoff timestamp after a recent failed auto refresh. |
| `hasCachedData` | `true` if DB-backed AA data already exists and can be shown immediately. |
| `items` | Per-consent / per-FIP child refresh status. Only present on operation-status style responses. |

## Frontend Scenarios

### 1. No active consent

Backend response:

```json
{
  "state": "no_consent",
  "lastSuccessfulRefreshAt": null,
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": false
}
```

Frontend behavior:

- Show empty AA state
- Show connect-consent CTA
- Do not poll

### 2. Data already fresh for today

Backend response:

```json
{
  "state": "already_fresh",
  "operationId": "b62a5679-4f5d-4f4d-b7fc-1af17e1aa8d1",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/b62a5679-4f5d-4f4d-b7fc-1af17e1aa8d1/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": "2026-05-01T08:14:12.110021+00:00",
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": true,
  "items": [
    {
      "consentId": "d3f2f0cf-59c5-4db1-bbb3-7bc9749a33e0",
      "consentHandle": "consent-handle-1",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "success",
      "requestId": "fetch-req-1",
      "fetchJobId": "bc7d1f73-5f66-4f09-91db-397e2f3cb580",
      "reason": null,
      "updatedAt": "2026-05-01T08:14:12.110021+00:00"
    }
  ]
}
```

Frontend behavior:

- Load dashboard / accounts / transactions normally
- Do not poll
- Optionally show "Last updated" from `lastSuccessfulRefreshAt`

### 3. New refresh started

Backend response:

```json
{
  "state": "started",
  "operationId": "1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": null,
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": true,
  "items": [
    {
      "consentId": "d3f2f0cf-59c5-4db1-bbb3-7bc9749a33e0",
      "consentHandle": "consent-handle-1",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "pending",
      "requestId": null,
      "fetchJobId": null,
      "reason": null,
      "updatedAt": "2026-05-01T08:20:51.002513+00:00"
    }
  ]
}
```

Frontend behavior:

- If `hasCachedData = true`
  - show existing dashboard / accounts immediately
  - show a small refresh indicator
- If `hasCachedData = false`
  - show a blocking skeleton briefly
- Start polling `statusUrl`

### 4. Refresh already in progress

Backend response:

```json
{
  "state": "in_progress",
  "operationId": "1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": null,
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": true,
  "items": [
    {
      "consentId": "d3f2f0cf-59c5-4db1-bbb3-7bc9749a33e0",
      "consentHandle": "consent-handle-1",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "in_progress",
      "requestId": "fetch-req-2",
      "fetchJobId": "b15f9a69-47d9-45ff-96d0-86d4b77db483",
      "reason": null,
      "updatedAt": "2026-05-01T08:22:11.119002+00:00"
    }
  ]
}
```

Frontend behavior:

- Same as `started`
- Do not trigger another refresh
- Poll `statusUrl`

### 5. Auto refresh skipped to preserve manual quota

Backend response:

```json
{
  "state": "skipped_quota",
  "lastSuccessfulRefreshAt": null,
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": true
}
```

Frontend behavior:

- Show stored data normally
- Do not poll
- Optional banner:
  - `Auto refresh skipped to preserve manual refresh quota`

### 6. Auto refresh failed recently and is in backoff

Backend response:

```json
{
  "state": "failed_recently",
  "operationId": "f7d44745-6fd4-472f-b20d-fd44c2b68b89",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/f7d44745-6fd4-472f-b20d-fd44c2b68b89/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": null,
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": "2026-05-01T08:45:00+00:00",
  "hasCachedData": true,
  "items": [
    {
      "consentId": "d3f2f0cf-59c5-4db1-bbb3-7bc9749a33e0",
      "consentHandle": "consent-handle-1",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "failed",
      "requestId": "fetch-req-3",
      "fetchJobId": "d3d8bd9e-1970-4f57-b0cf-a1e8bb9b7f10",
      "reason": "UPSTREAM_TIMEOUT",
      "updatedAt": "2026-05-01T08:30:00+00:00"
    }
  ]
}
```

Frontend behavior:

- Show stored data normally
- Do not keep retriggering on every reopen
- Optional banner:
  - `Refresh failed recently. We will try again later.`

### 7. Completed with partial failures

This can come from either the `POST` response or the polling `GET` response.

Example:

```json
{
  "state": "completed_with_partial_failures",
  "operationId": "ab3e65dd-6f62-45e0-ae67-b4d2ef6cfd01",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/ab3e65dd-6f62-45e0-ae67-b4d2ef6cfd01/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": "2026-05-01T08:41:20.100410+00:00",
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": true,
  "items": [
    {
      "consentId": "1",
      "consentHandle": "consent-success",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "success",
      "requestId": "fetch-success-1",
      "fetchJobId": "job-success-1",
      "reason": null,
      "updatedAt": "2026-05-01T08:41:20.100410+00:00"
    },
    {
      "consentId": "2",
      "consentHandle": "consent-failed",
      "fiType": "ETF",
      "fipId": "CDSLFIP",
      "fipName": "CDSLFIP",
      "state": "failed",
      "requestId": "fetch-failed-1",
      "fetchJobId": "job-failed-1",
      "reason": "FIP_FAILED",
      "updatedAt": "2026-05-01T08:41:15.220010+00:00"
    }
  ]
}
```

Frontend behavior:

- Show available data normally
- Stop polling if this came from `GET`
- Optional banner:
  - `Some institutions could not be refreshed`

## Polling Status Endpoint Examples

### `GET /aa/data/refresh/on-open/<operation_id>/` while still running

```json
{
  "state": "in_progress",
  "operationId": "1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": null,
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": true,
  "items": [
    {
      "consentId": "1",
      "consentHandle": "consent-1",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "in_progress",
      "requestId": "fetch-req-4",
      "fetchJobId": "job-4",
      "reason": null,
      "updatedAt": "2026-05-01T08:51:01.110221+00:00"
    }
  ]
}
```

### `GET /aa/data/refresh/on-open/<operation_id>/` when completed

```json
{
  "state": "completed",
  "operationId": "1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/1b4929fc-4f4f-43f5-b6aa-28bf22a8cc6d/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": "2026-05-01T08:52:16.000441+00:00",
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": null,
  "hasCachedData": true,
  "items": [
    {
      "consentId": "1",
      "consentHandle": "consent-1",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "success",
      "requestId": "fetch-req-4",
      "fetchJobId": "job-4",
      "reason": null,
      "updatedAt": "2026-05-01T08:52:16.000441+00:00"
    }
  ]
}
```

### `GET /aa/data/refresh/on-open/<operation_id>/` when failed

```json
{
  "state": "failed",
  "operationId": "f7d44745-6fd4-472f-b20d-fd44c2b68b89",
  "statusUrl": "/api/v1/aa/data/refresh/on-open/f7d44745-6fd4-472f-b20d-fd44c2b68b89/",
  "pollAfterSeconds": 2,
  "lastSuccessfulRefreshAt": null,
  "nextAutoRefreshAfter": "2026-05-02T00:00:00+05:30",
  "nextRetryAfter": "2026-05-01T08:45:00+00:00",
  "hasCachedData": true,
  "items": [
    {
      "consentId": "1",
      "consentHandle": "consent-1",
      "fiType": "MUTUAL_FUNDS",
      "fipId": "CAMSRTAFIP",
      "fipName": "CAMSRTAFIP",
      "state": "failed",
      "requestId": "fetch-req-5",
      "fetchJobId": "job-5",
      "reason": "UPSTREAM_TIMEOUT",
      "updatedAt": "2026-05-01T08:35:15.004112+00:00"
    }
  ]
}
```

## Recommended Frontend Behavior

## App-open flow

1. After user authentication, call:
   - `POST /api/v1/aa/data/refresh/on-open/`
2. Read `state`
3. Render the correct UI
4. If `state` is `started` or `in_progress`, poll `statusUrl`
5. When polling reaches `completed`, `completed_with_partial_failures`, or `failed`, reload the normal DB-backed AA data endpoints

## UI mapping

### If state is `no_consent`

- Show empty AA state
- Show connect-consent CTA

### If state is `already_fresh`

- Load normal AA data endpoints
- No polling

### If state is `started` or `in_progress`

- If `hasCachedData = true`
  - show dashboard / accounts immediately
  - show a non-blocking `Refreshing...` indicator
- If `hasCachedData = false`
  - show a blocking skeleton briefly
- Poll `statusUrl` every `pollAfterSeconds`

### If state is `skipped_quota`

- Show stored data
- Optional informational banner

### If state is `failed_recently`

- Show stored data
- Optional informational banner
- Do not immediately retry on every reopen

### If state is `completed_with_partial_failures`

- Show stored data
- Optional informational banner that some FIPs failed

## Polling stop conditions

Stop polling when `GET /aa/data/refresh/on-open/<operation_id>/` returns:

- `completed`
- `completed_with_partial_failures`
- `failed`

## Data reload after refresh

After polling completes, frontend should reload the normal AA data endpoints, for example:

- `GET /api/v1/aa/dashboard/networth/`
- `GET /api/v1/aa/dashboard/assets/`
- `GET /api/v1/aa/dashboard/portfolio/`
- `GET /api/v1/aa/dashboard/portfolio/all/`
- `GET /api/v1/aa/accounts/`
- `GET /api/v1/aa/transaction/all/`
- `GET /api/v1/aa/bank/transactions/`
- `GET /api/v1/aa/insurance/summary/`
- `GET /api/v1/aa/nps/`

Frontend should not use the app-open refresh endpoint itself as the source of dashboard data. It is only the control-plane endpoint for deciding whether refresh is needed and tracking the refresh operation.

## Important Notes

- Frontend should not implement its own "once per day" decision.
- Frontend should not call `fetch/all` on every app open anymore.
- Manual refresh can still use the existing manual fetch endpoints separately.
- `items` are useful for debugging, per-FIP UI, or partial-failure messaging, but the main screen data should still come from the normal AA read endpoints.

## Related Docs

- [finarkein_aa_backend_ui_guide.md](/c:/Users/shrav/Desktop/Programs/pivot-money/finarkin/PivotMoneyBackend/docs/bse/finarkein_aa_backend_ui_guide.md)
