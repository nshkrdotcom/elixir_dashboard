# What's Different: Before vs After ElixirTracer Integration

## TL;DR

**Before**: Simple duration tracking
**After**: Rich observability with Phoenix metadata, HTTP details, DB stats, errors, metrics, and custom events

---

## Data Collection

### Before (Legacy DETS)
```elixir
# Only captured:
%{
  path: "GET /demo/complex_query",
  duration_ms: 1639,
  timestamp: 1760770864568
}
```

### After (ElixirTracer)
```elixir
# Now captures:
%{
  path: "/Phoenix//demo/complex_query/ElixirDashboardWeb.Demo/complex_query",
  duration_ms: 1639,
  timestamp: 1760770864568,

  # NEW: Transaction tracking
  transaction_id: "23db9ae3dbc2e863",
  trace_id: "54d8c7250249c2da9a7a7a4771c3ff41",  # For distributed tracing
  status: :completed,
  error_count: 0,

  # NEW: Rich metadata automatically captured
  custom_attributes: %{
    # Phoenix metadata
    "phoenix.controller" => "ElixirDashboardWeb.DemoController",
    "phoenix.action" => "complex_query",
    "phoenix.endpoint" => "ElixirDashboardWeb.Endpoint",
    "phoenix.router" => "ElixirDashboardWeb.Router",
    "phoenix.format" => "json",

    # HTTP metadata
    "http.method" => "GET",
    "http.status_code" => 200,
    "http.url" => "/demo/complex_query",
    "request.method" => "GET",
    "request.uri" => "/demo/complex_query",
    "request.headers.host" => "localhost:4000",
    "request.headers.user_agent" => "Mozilla/5.0...",
    "response.status" => 200,

    # Database stats (automatically calculated!)
    :datastore_call_count => 1,        # How many DB queries
    :datastore_duration_ms => 1627,    # Time spent in DB
    :databaseDuration => 1.627,
    :databaseCallCount => 1
  }
}
```

---

## UI Display

### Before
```
┌─────────────────────────────────────────┐
│ Duration │ Path           │ Time        │
├─────────────────────────────────────────┤
│ 1639ms   │ GET /demo/slow │ 12:34:56    │
└─────────────────────────────────────────┘
```

### After
```
┌──────────────────────────────────────────────────────────────┐
│ Duration │ Path + Metadata                 │ Status │ Errors │
├──────────────────────────────────────────────────────────────┤
│ 1639ms   │ GET /demo/slow                  │ ✓      │   -    │
│          │ Controller: DemoController →... │        │        │
│          │ [Status: 200] [GET]             │        │        │
│          │ [1 DB queries] [1627ms in DB]   │        │        │
│          │ Trace ID: 54d8c725...           │        │        │
└──────────────────────────────────────────────────────────────┘
```

---

## Available Dashboards

### Before
1. `/dev/performance/endpoints` - Slow endpoints
2. `/dev/performance/queries` - Slow queries

**Total: 2 dashboards**

### After
1. `/dev/performance/endpoints` - **Enhanced** slow endpoints with rich metadata
2. `/dev/performance/queries` - **Enhanced** slow queries with DB details
3. `/dev/performance/errors` - **NEW** Exception tracking with stack traces
4. `/dev/performance/metrics` - **NEW** Aggregated performance data
5. `/dev/performance/events` - **NEW** Custom business events

**Total: 5 dashboards**

---

## What You Can See Now (That You Couldn't Before)

### 1. **Controller & Action Information**
- See exactly which controller/action handled the request
- Example: `ElixirDashboardWeb.DemoController → complex_query`

### 2. **HTTP Status Codes**
- Color-coded status badges (green for 2xx, orange for 4xx, red for 5xx)
- HTTP method badges (GET, POST, etc.)

### 3. **Database Performance Breakdown**
- **Query count** per request
- **Time spent in database** vs total time
- Example: "1 DB queries, 1627ms in DB" for a 1639ms total request

### 4. **Distributed Tracing**
- Trace IDs that link requests across services
- Can correlate with external systems using W3C Trace Context

### 5. **Error Correlation**
- See error count per endpoint
- Click through to errors dashboard to see full stack traces

### 6. **Transaction Status**
- Visual indicators: ✓ Success vs ✗ Error
- Filter by status

### 7. **Database Query Details** (Queries page)
- **Operation type**: SELECT, INSERT, UPDATE, DELETE
- **Table name**: Extracted from query
- **Database instance**: Which DB server
- **Span IDs**: For correlation

### 8. **Error Tracking** (Errors page)
- Exception type and message
- Full stack traces
- Which transaction triggered the error
- Custom context attributes

### 9. **Performance Metrics** (Metrics page)
- Aggregated data by operation
- Call counts, min/max/avg durations
- Filter by: Database, External services, Custom metrics

### 10. **Custom Events** (Events page)
- Track business events (signups, purchases, etc.)
- Filter by event type
- Time-based statistics

---

## Real Example: What You See Now

### Request to `/demo/complex_query`

**Before:**
```
Duration: 1639ms
Path: GET /demo/complex_query
Time: 2025-10-17 12:34:56
```

**After:**
```
Duration: 1639ms
Path: /Phoenix//demo/complex_query/ElixirDashboardWeb.Demo/complex_query

Controller: ElixirDashboardWeb.DemoController → complex_query

Status: 200 (✓ Success)
Method: GET

Database Performance:
  • 1 DB queries
  • 1627ms in DB (99% of total time!)

Trace ID: 54d8c725... (for distributed tracing)
Transaction ID: 23db9ae3...
```

---

## Technical Improvements

### Data Storage

**Before:**
- 2 DETS files: `endpoints.dets`, `queries.dets`
- Simple maps with 3-4 fields each

**After:**
- 5 DETS files: `transactions.dets`, `spans.dets`, `errors.dets`, `metrics.dets`, `events.dets`
- Rich structs with 15+ fields
- Full New Relic Agent API parity

### Telemetry Handlers

**Before:**
- 2 custom handlers (Phoenix endpoint, Ecto query)
- Manual correlation via process dictionary

**After:**
- ElixirTracer's comprehensive handlers:
  - PlugHandler (auto-creates transactions)
  - PhoenixHandler (enriches with route/controller)
  - EctoHandler (creates datastore spans)
- Automatic parent-child span relationships
- W3C Trace Context propagation

### Query Capabilities

**Before:**
```elixir
# Simple list retrieval
ElixirDashboard.PerformanceMonitor.get_slow_endpoints()
```

**After:**
```elixir
# Rich querying via ElixirTracer
ElixirTracer.Query.get_transactions(
  type: :web,
  status: :error,
  sort: :duration_desc,
  limit: 10
)

# With full filtering
ElixirTracer.Query.get_errors(limit: 50)
ElixirTracer.Query.get_metrics()
ElixirTracer.Query.get_custom_events()
```

---

## How to See the Difference

1. **Visit the enhanced Endpoints page:**
   ```
   http://localhost:4000/dev/performance/endpoints
   ```
   - Look for controller/action names
   - HTTP status badges
   - Database stats (query count, DB time)
   - Trace IDs

2. **Visit the enhanced Queries page:**
   ```
   http://localhost:4000/dev/performance/queries
   ```
   - Look for operation type badges (SELECT, INSERT, etc.)
   - Table names
   - Database instance info

3. **Try the NEW dashboards:**
   ```
   http://localhost:4000/dev/performance/errors
   http://localhost:4000/dev/performance/metrics
   http://localhost:4000/dev/performance/events
   ```

4. **Generate some test data:**
   ```bash
   # In terminal
   mix dashboard.test 10

   # Then refresh the dashboards
   ```

---

## The Key Difference

### Before: "What happened?"
- Slow endpoint: 1639ms
- Slow query: 1627ms

### After: "What happened, WHY, and CONTEXT?"
- Slow endpoint: 1639ms
  - **Which controller/action**: DemoController.complex_query
  - **HTTP details**: GET request, 200 OK
  - **Database impact**: 1 query taking 1627ms (99% of time!)
  - **Tracing**: Trace ID for correlation
  - **Status**: Successful completion, no errors

You went from **basic duration tracking** to **comprehensive observability** with full context!

---

## Summary

ElixirTracer doesn't just collect more data—it provides **actionable insights**:

✅ **See controller/action** that handled request
✅ **Understand HTTP context** (method, status, headers)
✅ **Identify database bottlenecks** (% time in DB)
✅ **Track errors** with full stack traces
✅ **Correlate across services** with distributed tracing
✅ **Aggregate metrics** to find patterns
✅ **Track business events** for product analytics

All while maintaining **100% backward compatibility** with your existing dashboard!
