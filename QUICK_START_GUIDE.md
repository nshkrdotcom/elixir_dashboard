# Quick Start Guide - See All ElixirTracer Features

## TL;DR - Show Me Everything Now!

```bash
# 1. Start the server
mix phx.server

# 2. In another terminal - generate ALL the data
mix dashboard.test 10      # Slow endpoints & queries
mix dashboard.fixtures     # Errors, metrics, events

# 3. Open your browser
open http://localhost:4000/dev/performance/endpoints
open http://localhost:4000/dev/performance/queries
open http://localhost:4000/dev/performance/errors
open http://localhost:4000/dev/performance/metrics
open http://localhost:4000/dev/performance/events
```

**Done!** All 5 dashboards are now populated with realistic data.

---

## Step-by-Step Walkthrough

### Step 1: Start the Development Server

```bash
mix phx.server
```

Wait for:
```
[info] ElixirTracer handlers attached successfully
[info] TracerStore initialized - using ElixirTracer backend
```

### Step 2: Generate Test Data

#### For Endpoints & Queries Dashboards

```bash
# In a new terminal
mix dashboard.test 10
```

This makes **HTTP requests** to demo endpoints, which creates:
- ✅ Real web transactions (captured by ElixirTracer.Telemetry.PlugHandler)
- ✅ Real database queries (captured by ElixirTracer.Telemetry.EctoHandler)
- ✅ Full transaction context (controller, HTTP status, etc.)

#### For Errors, Metrics & Events Dashboards

```bash
mix dashboard.fixtures
```

This generates **fixture data** directly:
- ✅ 5 realistic errors with stack traces
- ✅ Comprehensive performance metrics
- ✅ 10 business events (signups, purchases, etc.)

**Custom counts**:
```bash
mix dashboard.fixtures --errors 10 --events 20
```

### Step 3: Explore the Dashboards

#### 1. Endpoints (`/dev/performance/endpoints`)

**What You'll See**:
- Duration in milliseconds
- Full endpoint path
- **Controller & action** (e.g., "DemoController → complex_query")
- **HTTP status code** with color (green=200, orange=400, red=500)
- **Database stats**: "1 DB queries", "1627ms in DB"
- **Trace ID** for distributed tracing
- **Transaction status** (✓ Success / ✗ Error)

**Example**:
```
1639ms  /Phoenix//demo/complex_query/ElixirDashboardWeb.Demo/complex_query
        Controller: ElixirDashboardWeb.DemoController → complex_query
        [Status: 200] [GET]
        [1 DB queries] [1627ms in DB]
```

#### 2. Queries (`/dev/performance/queries`)

**What You'll See**:
- Query duration
- Full SQL text
- **Operation type** badge (SELECT, INSERT, UPDATE)
- **Table name** badge
- **Database instance** and hostname
- **Span ID** for correlation
- Originating endpoint

**Example**:
```
1627ms  [SELECT] [demo_users]

Endpoint: /Phoenix//demo/complex_query/...
Database: unknown
Host: unknown
Span ID: 49f7271d...

SQL Query:
SELECT u.name, u.email, COUNT(p.id) as post_count...
```

#### 3. Errors (`/dev/performance/errors`) **NEW!**

**What You'll See**:
- Total errors, error types, most common
- **Error type** (Ecto.NoResultsError, RuntimeError, etc.)
- **Exception message**
- **Transaction correlation** (which endpoint triggered it)
- **Stack trace** (collapsible)
- **Context attributes** (user_id, resource, severity)

**Example**:
```
[Elixir.Ecto.NoResultsError]

expected at least one result but got none in query

Transaction: /api/products/list
Context:
  [resource: User] [id: 350] [severity: high]

Stack Trace (click to expand)
```

#### 4. Metrics (`/dev/performance/metrics`) **NEW!**

**What You'll See**:
- Tabs: All / Database / External / Custom
- **Call counts** for each operation
- **Total time**, **Average**, **Min**, **Max**
- Sorted by total time (slowest first)

**Example**:
```
[Database]
Datastore/PostgreSQL/users/SELECT    45 calls  4.5s total  100ms avg  50ms min  500ms max
Datastore/PostgreSQL/orders/INSERT   20 calls  1.2s total   60ms avg  30ms min  120ms max

[External]
External/api.stripe.com/POST         15 calls  2.3s total  153ms avg  80ms min  350ms max
```

#### 5. Events (`/dev/performance/events`) **NEW!**

**What You'll See**:
- Total events, event types, last hour activity
- **Filter by event type** dropdown
- **Event attributes** (all custom data)
- Timestamp for each event

**Example**:
```
Stats: 10 total | 6 types | 3 in last hour

[PurchaseCompleted]
Event Data:
  order_id: ord_a3f2b1c5e6d7
  amount: 249.99
  currency: USD
  items_count: 3
  payment_method: stripe
  user_id: 742

[UserSignup]
Event Data:
  email: alice342@gmail.com
  plan: pro
  source: google_ads
  country: US
  device: desktop
```

---

## What Makes This Different?

### Before ElixirTracer

```
Endpoint: GET /demo/complex_query
Duration: 1639ms
Time: 2025-10-17 12:34:56
```

That's it. Just duration and path.

### After ElixirTracer

```
Endpoint: /Phoenix//demo/complex_query/ElixirDashboardWeb.Demo/complex_query
Duration: 1639ms

Controller: ElixirDashboardWeb.DemoController → complex_query
HTTP Status: 200 (Success)
Method: GET

Database Performance:
  • 1 DB queries
  • 1627ms in DB (99% of total time!)

Trace ID: 54d8c725... (for distributed tracing)
Transaction ID: 23db9ae3...

Plus 3 NEW dashboards:
  • Errors with stack traces
  • Metrics with aggregation
  • Events for business tracking
```

---

## Common Workflows

### Demo to Someone

```bash
# 1. Clear old data
mix dashboard.clear

# 2. Generate fresh data
mix dashboard.test 15
mix dashboard.fixtures --errors 8 --events 15

# 3. Show them the dashboards
# All populated with realistic data!
```

### Test a Specific Feature

```bash
# Test error tracking
iex -S mix phx.server

# In IEx:
ElixirTracer.OtherTransaction.start_transaction("Test", "MyFeature")
ElixirTracer.Error.Reporter.notice_error(
  %RuntimeError{message: "Something went wrong"},
  %{user_id: 123, feature: "export"}
)
ElixirTracer.OtherTransaction.stop_transaction()

# Check /dev/performance/errors - your error is there!
```

### Monitor Real Development Work

```bash
# Just start the server and work normally
mix phx.server

# Make requests to your app as you develop
curl http://localhost:4000/api/users
curl http://localhost:4000/api/orders

# Check dashboards to see performance
# Automatically tracked - no extra code needed!
```

---

## Tips & Tricks

### 1. Auto-Refresh

All dashboards auto-refresh every 5 seconds. You can:
- Generate data in terminal
- Watch it appear in real-time in browser

### 2. Filtering

**Metrics Dashboard**: Click tabs to filter by category
- All Metrics
- Database only
- External services only
- Custom metrics only

**Events Dashboard**: Use dropdown to filter by event type
- All Events
- UserSignup
- PurchaseCompleted
- etc.

### 3. Clearing Data

```bash
# Clear everything
mix dashboard.clear

# Or use the UI
# Click "Clear Data" button on any dashboard
```

### 4. View Statistics

```bash
mix dashboard.stats
```

Shows:
- Total endpoints, queries, errors, metrics, events
- Top 5 slowest items
- Storage info

---

## Troubleshooting

### "No data appearing"

**Solution**: Make sure you've generated data!

```bash
# For endpoints/queries
mix dashboard.test 10

# For errors/metrics/events
mix dashboard.fixtures
```

### "Empty dashboards after generating fixtures"

**Solution**: Refresh your browser (dashboards auto-refresh every 5s)

Or check that the server is running:
```bash
# Should see this when server starts:
[info] ElixirTracer handlers attached successfully
[info] TracerStore initialized - using ElixirTracer backend
```

### "Server not running error"

**Solution**: `mix dashboard.test` requires a running server

```bash
# Terminal 1
mix phx.server

# Terminal 2
mix dashboard.test 10
```

---

## Summary

### To See Everything:

```bash
# 1. Start server
mix phx.server

# 2. Generate all data types
mix dashboard.test 10       # Endpoints & queries
mix dashboard.fixtures      # Errors, metrics, events

# 3. Visit dashboards
http://localhost:4000/dev/performance/endpoints   # Enhanced with controller/HTTP/DB info
http://localhost:4000/dev/performance/queries     # Enhanced with operation/table/span info
http://localhost:4000/dev/performance/errors      # NEW - Exception tracking
http://localhost:4000/dev/performance/metrics     # NEW - Performance aggregation
http://localhost:4000/dev/performance/events      # NEW - Business events
```

### You'll See:

✅ **Rich transaction data** (not just durations)
✅ **Controller & action names**
✅ **HTTP status codes** with colors
✅ **Database performance** (query counts, time in DB)
✅ **Error traces** with stack traces
✅ **Aggregated metrics** (call counts, min/max/avg)
✅ **Business events** (signups, purchases, etc.)
✅ **Distributed tracing** (trace IDs)

All powered by ElixirTracer's comprehensive observability! 🎉
