# Fixture System for ElixirTracer Dashboards

## Overview

A robust, realistic fixture data generator for populating all ElixirTracer dashboards with test data.

## Design Principles

1. **Realism**: Data mirrors real-world scenarios (actual error types, realistic business events, varied metrics)
2. **Variety**: 8+ error types, 8+ event types, comprehensive metrics coverage
3. **Configurability**: Adjustable counts via command-line options
4. **Consistency**: Follows established `mix dashboard.*` task pattern
5. **Documentation**: Each generator well-documented with realistic attributes

## Architecture

```
lib/elixir_dashboard/
├── fixtures.ex                    # Core fixture generator
└── mix/tasks/dashboard.ex
    └── Mix.Tasks.Dashboard.Fixtures  # CLI task
```

### Fixtures Module

**Location**: `lib/elixir_dashboard/fixtures.ex`

**Public API**:
```elixir
ElixirDashboard.Fixtures.generate_all(opts)      # All fixtures
ElixirDashboard.Fixtures.generate_errors(count)  # Error traces
ElixirDashboard.Fixtures.generate_metrics()      # Performance metrics
ElixirDashboard.Fixtures.generate_events(count)  # Business events
```

## Generated Data

### 1. Errors (5 default, configurable)

**8 Error Templates**:
1. `Ecto.NoResultsError` - Database record not found
2. `Phoenix.Router.NoRouteError` - Invalid route
3. `DBConnection.ConnectionError` - Database connection timeout
4. `ArgumentError` - Invalid function arguments
5. `RuntimeError` - External API failures
6. `KeyError` - Missing required keys
7. `FunctionClauseError` - Pattern matching failures
8. `Jason.DecodeError` - JSON parsing errors

**Each Error Includes**:
- Transaction context (path, user_id, session_id)
- Error type and message
- Custom context attributes
- Full stack trace
- Severity level (low/medium/high/critical)

### 2. Metrics (Comprehensive)

#### Database Metrics
- **Tables**: users, orders, products, sessions
- **Operations**: SELECT, INSERT, UPDATE, DELETE
- **Patterns**:
  - SELECT: 10-50 calls, 0-100ms each
  - INSERT: 10-50 calls, 0-50ms each
  - Occasional 10x slower queries (simulating slow queries)

#### External Service Metrics
- **Services**: Stripe, SendGrid, S3, GitHub
- **Operations**: GET, POST, PUT
- **Patterns**: 5-30 calls, 0-500ms each

#### Custom Metrics
- Cache hits/misses (counters)
- Queue jobs processed (counters)
- Email sent (counters)
- Image processing time (durations)
- API rate limiting (counters)

### 3. Custom Events (10 default, configurable)

**8 Event Types**:

1. **UserSignup**
   - email, plan (free/starter/pro/enterprise)
   - source (google_ads/organic/referral/direct)
   - campaign, country, device

2. **PurchaseCompleted**
   - order_id, amount, currency
   - items_count, payment_method
   - discount_applied, user_id

3. **FeatureUsed**
   - feature (pdf_export/csv_import/api_access/analytics/webhooks)
   - user_id, duration_ms, success, plan

4. **SubscriptionChanged**
   - from_plan, to_plan, change_type (upgrade/downgrade)
   - annual, mrr_change

5. **PaymentFailed**
   - amount, reason (insufficient_funds/card_declined/etc.)
   - retry_count, subscription_id

6. **UserLogin**
   - method (password/google/github/saml)
   - device, location, ip_address, success

7. **ExportGenerated**
   - format (csv/xlsx/pdf/json)
   - records_count, file_size_mb, duration_seconds

8. **ApiKeyCreated**
   - key_id, scopes, environment
   - expires_at

## Usage

### CLI Task

```bash
# Generate all fixtures with defaults (5 errors, 10 events, all metrics)
mix dashboard.fixtures

# Generate with custom counts
mix dashboard.fixtures --errors 10 --events 20

# Short flags
mix dashboard.fixtures -e 15 -v 25
```

### Programmatic Usage

```elixir
# In IEx or code
ElixirDashboard.Fixtures.generate_all()

# Custom counts
ElixirDashboard.Fixtures.generate_all(errors: 10, events: 20)

# Individual generators
ElixirDashboard.Fixtures.generate_errors(5)
ElixirDashboard.Fixtures.generate_metrics()
ElixirDashboard.Fixtures.generate_events(10)
```

## Helper Functions

**Realistic Data Generators**:
- `random_email()` - Generates realistic email addresses
- `random_session_id()` - Session IDs with prefix
- `random_request_id()` - Request IDs with prefix
- `random_id()` - 16-character hex IDs
- `random_ip()` - IPv4 addresses
- `random_endpoint()` - API endpoint paths

## Integration with Existing System

### Consistent with `mix dashboard.*` Tasks

```bash
# Existing tasks
mix dashboard.test 20        # HTTP requests → endpoints/queries
mix dashboard.slow_query     # Direct DB query
mix dashboard.stats          # Show statistics
mix dashboard.clear          # Clear all data

# New task
mix dashboard.fixtures       # Errors/metrics/events
```

### Data Visibility

```bash
# Generate fixtures
mix dashboard.fixtures --errors 8 --events 15

# View in dashboards
open http://localhost:4000/dev/performance/errors
open http://localhost:4000/dev/performance/metrics
open http://localhost:4000/dev/performance/events
```

## Example Output

```
📊 Generating fixture data...

Generating 5 error traces...
  ✓ 5 errors generated

Generating performance metrics...
  ✓ Database metrics generated
  ✓ External service metrics generated
  ✓ Custom metrics generated

Generating 10 custom events...
  ✓ 10 events generated

✨ Fixture generation complete!

View the data in your dashboards:
  http://localhost:4000/dev/performance/errors
  http://localhost:4000/dev/performance/metrics
  http://localhost:4000/dev/performance/events
```

## Benefits

### 1. Realistic Demonstration
- Shows what the dashboards look like with real data
- Demonstrates all features (error context, stack traces, metrics aggregation, event filtering)

### 2. Testing & Development
- Quickly populate dashboards during development
- Test UI with varied data patterns
- Verify ElixirTracer integration

### 3. Documentation & Demos
- Screenshots with real-looking data
- Demo videos with populated dashboards
- User onboarding with example data

### 4. QA & Validation
- Ensure all dashboard features work
- Test edge cases (empty states, large numbers, etc.)
- Validate data transformations

## Technical Details

### Transaction Context
Every error is wrapped in a transaction:
```elixir
ElixirTracer.OtherTransaction.start_transaction(
  "WebTransaction",
  "/api/#{random_endpoint()}"
)

ElixirTracer.Transaction.Reporter.add_attributes(%{
  user_id: :rand.uniform(1000),
  session_id: random_session_id(),
  request_id: random_request_id()
})

ElixirTracer.Error.Reporter.notice_error(exception, context)

ElixirTracer.OtherTransaction.stop_transaction()
```

### Metric Patterns
Metrics use realistic patterns:
- **Call counts**: Varied (10-100 calls per metric)
- **Durations**: Operation-specific (SELECT slower than INSERT)
- **Outliers**: Occasional 10x slower calls (simulating N+1, missing indexes, etc.)

### Event Realism
Events use business-realistic attributes:
- **Amounts**: Realistic pricing ($0.01 - $500.00)
- **Distributions**: Weighted randomness (90% success, 10% failure)
- **Timestamps**: Slight delays between events (5-10ms)

## Future Enhancements

### Planned
- [ ] `--slow-queries` flag to generate N+1 patterns
- [ ] `--distributed-trace` flag to create cross-service traces
- [ ] Template-based fixtures (load from YAML/JSON)
- [ ] Time-series data (generate historical trends)

### Possible
- [ ] Fixture presets (`--preset production-like`)
- [ ] Fixture cleanup (`mix dashboard.fixtures.clear`)
- [ ] Export fixtures to JSON for replay
- [ ] Import real production data (anonymized)

## Summary

The fixture system provides:

✅ **8 realistic error types** with full context
✅ **Comprehensive metrics** (DB, external, custom)
✅ **8 business event types** with realistic attributes
✅ **CLI task** following existing patterns
✅ **Programmatic API** for flexibility
✅ **Configurable counts** via command-line options
✅ **Helper functions** for realistic data generation

This enables quick demonstration and testing of all ElixirTracer dashboard features without needing a running application with real traffic.
