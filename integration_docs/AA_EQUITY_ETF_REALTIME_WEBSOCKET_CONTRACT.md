# Frontend Realtime WebSocket Contract

This document defines the proposed client-facing realtime contract for live AA equity/ETF market data.

It is intentionally separate from the Zerodha ingestion layer.

Backend responsibilities:

- consume Zerodha ticks centrally
- keep latest live state in Redis
- compute user-scoped portfolio updates
- push app-level realtime events to frontend

Frontend responsibilities:

- open one authenticated realtime connection per user session
- maintain snapshot + delta state
- render live price, current value, day gain, and day gain %

This contract is not implemented yet as a public socket endpoint. It is the target contract for backend and frontend to build against in parallel.

## Goals

- one backend-global Zerodha market stream
- one frontend websocket per logged-in user session
- no raw Zerodha ticks sent to frontend
- backend sends only user-scoped computed updates
- backend derives the live holdings scope automatically from the authenticated user
- overall portfolio totals should be pushed along with holding-level updates

## Phase 1 Scope

Phase 1 focuses only on:

- AA-backed live equity holdings
- AA-backed live ETF holdings
- live price
- current value
- day gain
- day gain %
- top-level overall portfolio totals for the user's live-supported equity/ETF universe

Explicitly out of scope for phase 1:

- order updates
- broker lifecycle events
- mutual fund live updates
- bank/NPS/insurance realtime updates
- live total-gain calculations that depend on unreliable cost basis

## Recommended Connection Design

Use a short-lived websocket ticket instead of sending long-lived JWT directly in the websocket URL.

Phase 1 should be backend-driven:

- frontend does not send ISINs
- backend identifies the user from auth
- backend loads the user's active AA equity/ETF holdings
- backend automatically starts the live portfolio session for that user
- backend pushes overall portfolio totals plus holding-level changes

This is the preferred approach for phase 1 because backend remains the source of truth for what the user actually holds.

## When To Create The Realtime Session

Create the realtime session only when the user opens a screen that needs live market data.

Recommended flow:

1. user logs in through the normal app auth flow
2. user opens dashboard / portfolio / holdings screen
3. frontend calls realtime bootstrap endpoint
4. backend creates a short-lived websocket ticket
5. frontend connects websocket
6. backend starts the user-scoped live session and sends snapshot

Do not open this socket eagerly for every authenticated app page if the page does not need live market data.

## Connection Lifecycle

### 1. Ticket bootstrap

Frontend first calls a normal authenticated REST endpoint:

```http
POST /api/v1/realtime/session/
Authorization: Bearer <jwt>
```

Suggested response:

```json
{
  "success": true,
  "data": {
    "ws_url": "wss://testing.pivotmoney.app/ws/v1/realtime/?ticket=rtm_abc123",
    "expires_in_seconds": 60,
    "session_id": "rtm_sess_01"
  }
}
```

Notes:

- backend validates JWT using the existing REST auth flow
- backend creates a short-lived websocket ticket in Redis/DB
- frontend uses the returned `ws_url` immediately
- backend can optionally return a small capability block later, but phase 1 can stay minimal

### 2. Websocket connect

Suggested websocket endpoint:

```text
wss://testing.pivotmoney.app/ws/v1/realtime/?ticket=<short_lived_ticket>
```

### 3. Server hello

On successful connect/auth, backend sends:

```json
{
  "type": "hello",
  "connection_id": "rtm_conn_01",
  "session_id": "rtm_sess_01",
  "server_time": "2026-05-21T10:15:04Z",
  "available_topics": ["portfolio"],
  "heartbeat_interval_seconds": 25
}
```

### 4. Client start message

Phase 1 should not require the frontend to send a holdings list or ISIN list.

Minimal client message:

```json
{
  "type": "start",
  "topic": "portfolio"
}
```

Rules:

- frontend does not send ISINs in phase 1
- backend derives the effective live universe from:
  - current authenticated user
  - active AA holdings
  - supported live-mapped equity/ETF ISINs
- frontend does not decide entitlement; backend does
- if later we need screen-level filtering, that can be added as a future optional optimization, not phase 1

### 5. Server subscribed ack

```json
{
  "type": "subscribed",
  "topic": "portfolio",
  "effective_holdings_count": 42,
  "live_supported_holdings_count": 39,
  "unsupported_holdings_count": 3
}
```

## Event Model

Backend should send snapshot first, then deltas.

### 1. Portfolio snapshot

Sent immediately after a successful portfolio start.

```json
{
  "type": "portfolio.snapshot",
  "as_of_at": "2026-05-21T10:15:05Z",
  "totals": {
    "market_value": 1234567.89,
    "day_gain": 12450.12,
    "day_gain_pct": 1.02,
    "live_holdings_count": 39,
    "unsupported_holdings_count": 3
  },
  "holdings": [
    {
      "isin": "INE002A01018",
      "symbol": "RELIANCE",
      "exchange": "BSE",
      "last_price": 2890.25,
      "previous_close": 2858.20,
      "quantity": 10,
      "market_value": 28902.50,
      "day_gain": 320.50,
      "day_gain_pct": 1.12
    },
    {
      "isin": "INE009A01021",
      "symbol": "INFY",
      "exchange": "BSE",
      "last_price": 1542.10,
      "previous_close": 1525.40,
      "quantity": 5,
      "market_value": 7710.50,
      "day_gain": 83.50,
      "day_gain_pct": 1.09
    }
  ],
  "unsupported_holdings": [
    {
      "isin": "INE0XXXX01010",
      "name": "Example Special Security",
      "reason": "not_live_mapped"
    }
  ]
}
```

Notes:

- `totals` is for the user's overall live-supported equity/ETF portfolio in scope for phase 1
- `holdings` contains the live-supported holdings
- `unsupported_holdings` is optional but useful so frontend can explain why some holdings are not moving live

### 2. Portfolio delta

Sent only for changed rows/totals.

```json
{
  "type": "portfolio.delta",
  "as_of_at": "2026-05-21T10:15:06Z",
  "totals": {
    "market_value": 1234890.64,
    "day_gain": 12772.87,
    "day_gain_pct": 1.05
  },
  "holdings": [
    {
      "isin": "INE002A01018",
      "symbol": "RELIANCE",
      "exchange": "BSE",
      "last_price": 2894.40,
      "previous_close": 2858.20,
      "quantity": 10,
      "market_value": 28944.00,
      "day_gain": 362.00,
      "day_gain_pct": 1.27
    }
  ]
}
```

Delta rules:

- omit unchanged holdings
- always send updated totals if totals changed
- if backend wants to reduce chatter, it can batch updates to `500ms` to `1s`

### 3. Error

```json
{
  "type": "error",
  "code": "invalid_start_payload",
  "message": "topic must be portfolio"
}
```

## Heartbeat

### Client ping

```json
{
  "type": "ping",
  "sent_at": "2026-05-21T10:15:25Z"
}
```

### Server pong

```json
{
  "type": "pong",
  "server_time": "2026-05-21T10:15:25Z"
}
```

Recommended:

- server heartbeat interval: `25s`
- frontend should consider connection stale if no server message is received for `45s`

## Retry / Reconnect Behavior

Frontend should reconnect automatically.

Recommended backoff:

1. retry after `1s`
2. retry after `2s`
3. retry after `5s`
4. retry after `10s`
5. retry after `20s`
6. cap at `30s`

Rules:

- if websocket closes because ticket expired before connect, obtain a new ticket first
- on reconnect, frontend should:
  - create a fresh realtime ticket
  - reconnect websocket
  - send the `start` message again
- frontend should treat every reconnect as state loss until a new `portfolio.snapshot` arrives

## Close Behavior

Suggested close codes:

- `4001`: unauthenticated / invalid ticket
- `4002`: subscription not allowed
- `4003`: malformed message
- `4004`: session superseded
- `1011`: internal server error

Frontend behavior:

- `4001`: refresh auth/ticket, then reconnect
- `4002`: stop retrying until the page/session is reinitialized
- `4003`: log and fix client payload
- `4004`: reconnect and re-bootstrap
- `1011`: exponential backoff retry

## Backend Computation Rules

Backend should not push raw ticks.

For portfolio events, backend computes:

- `last_price`
- `market_value = quantity * last_price`
- `day_gain = quantity * (last_price - previous_close)`
- `day_gain_pct = day_gain / (quantity * previous_close) * 100`

Notes:

- `total_gain` and `avg_buy_price` should be phase 2 unless transaction cost basis is already reliable
- unmapped / unsupported ISINs should be omitted from live deltas and optionally surfaced in the snapshot metadata

## Suggested Frontend Reducer Model

Frontend should keep state keyed by `isin`.

Suggested flow:

1. on `portfolio.snapshot`
  - replace current portfolio live state
  - replace top-level totals
  - replace unsupported holdings metadata
2. on `portfolio.delta`
  - patch only changed holdings
  - replace top-level totals
3. on reconnect
  - mark live state as reconnecting
  - wait for fresh snapshot

## Minimum Backend Deliverables

Backend should implement:

1. `POST /api/v1/realtime/session/`
2. `wss://.../ws/v1/realtime/?ticket=...`
3. `hello`
4. `start` client message handling
5. `subscribed`
6. `portfolio.snapshot`
7. `portfolio.delta`
8. `ping/pong`
9. `error`

## Minimum Frontend Deliverables

Frontend can start now with:

1. websocket client manager
2. reconnect/backoff logic
3. snapshot + delta reducer
4. holding state keyed by `isin`
5. live badge / reconnecting UI state
6. screen-level lifecycle:
   - create realtime session when dashboard/portfolio opens
   - close socket when page/module no longer needs live updates
7. simple `start portfolio` init message after connect

## Current Assumptions

- backend Zerodha ingestion remains one shared stream
- Redis remains the realtime internal source of truth
- DB remains durable snapshot/history storage only
- websocket is the long-term app realtime transport, not SSE
- phase 1 frontend consumption is portfolio-only for AA equity/ETF live data
- phase 1 holdings scope is derived entirely by backend from the authenticated user, not from client-supplied ISINs
