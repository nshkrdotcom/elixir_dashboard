  Integration Design: ElixirDashboard + ElixirTracer

  Executive Summary

  ElixirDashboard is a Phoenix LiveView performance monitoring tool focused on tracking slow
   endpoints and queries during development. ElixirTracer provides comprehensive local-first
   observability with full New Relic API parity, including transactions, spans, errors,
  metrics, and custom events.

  The integration will leverage ElixirTracer's rich tracing capabilities to enhance
  ElixirDashboard with deeper insights while maintaining backward compatibility.

  ---
  Current Architecture Analysis

  ElixirDashboard (Current State)

  - Storage: DETS-based persistence (priv/dets/)
    - endpoints.dets - Slow endpoints
    - queries.dets - Slow queries
  - Telemetry: Captures Phoenix and Ecto events
    - [:phoenix, :endpoint, :stop] → endpoint tracking
    - [app, :repo, :query] → query tracking
  - LiveView Pages:
    - /dev/performance/endpoints - slow endpoints
    - /dev/performance/queries - slow database queries
  - Data Model: Simple maps with duration, timestamp, path

  ElixirTracer Capabilities

  - Transactions: Web and background job tracking
  - Spans: Nested operation tracking (DB, HTTP, generic)
  - Errors: Exception tracking with context
  - Metrics: Aggregated performance data with stats
  - Custom Events: Business event tracking
  - Distributed Tracing: W3C Trace Context support
  - Storage: DETS-based (priv/dets/)
    - 5 separate tables with rich data structures

  ---
  Proposed Integration Architecture

  Phase 1: Unified Storage Layer (Foundation)

  Goal: Replace ElixirDashboard's simple DETS storage with ElixirTracer's comprehensive
  storage.

  Changes:

  1. Deprecate ElixirDashboard.PerformanceMonitor.DetsStore
  2. Create ElixirDashboard.PerformanceMonitor.TracerStore (facade over ElixirTracer)
  3. Maintain same public API for backward compatibility

  # lib/elixir_dashboard/performance_monitor/tracer_store.ex
  defmodule ElixirDashboard.PerformanceMonitor.TracerStore do
    @moduledoc """
    Storage adapter using ElixirTracer's comprehensive observability backend.
    Provides backward-compatible API while leveraging rich tracing data.
    """

    # Delegates to ElixirTracer.Query for data retrieval
    # Maps ElixirTracer transactions → dashboard endpoints
    # Maps ElixirTracer spans (datastore) → dashboard queries
  end

  Benefits:
  - No breaking changes to existing ElixirDashboard API
  - Gain access to ElixirTracer's rich data structures
  - Single source of truth for performance data

  ---
  Phase 2: Enhanced Telemetry Integration

  Goal: Use ElixirTracer's telemetry handlers while maintaining ElixirDashboard's
  thresholds.

  Changes:

  1. Replace custom telemetry handlers with ElixirTracer handlers
  2. Extend ElixirTracer handlers to respect ElixirDashboard thresholds
  3. Add automatic transaction creation for Phoenix requests

  # lib/elixir_dashboard/performance_monitor/telemetry_handler.ex
  defmodule ElixirDashboard.PerformanceMonitor.TelemetryHandler do
    @moduledoc """
    Enhanced telemetry handler using ElixirTracer's instrumentation.
    """

    def attach do
      # Attach ElixirTracer's handlers
      ElixirTracer.Telemetry.PlugHandler.attach()
      ElixirTracer.Telemetry.PhoenixHandler.attach()

      # Get configured repo prefixes
      repo_prefixes = Application.get_env(:elixir_dashboard, :repo_prefixes, [])
      ElixirTracer.Telemetry.EctoHandler.attach(repo_prefixes)

      # Attach custom handlers for dashboard-specific filtering
      :telemetry.attach_many(
        "elixir-dashboard-tracer-integration",
        [
          [:phoenix, :endpoint, :stop],
          [:ecto, :repo, :query]
        ],
        &__MODULE__.handle_event/4,
        nil
      )
    end

    def handle_event(event, measurements, metadata, _config) do
      # Apply dashboard-specific thresholds
      # Mark transactions for dashboard display based on thresholds
      # Add custom attributes for dashboard correlation
    end
  end

  Benefits:
  - Automatic transaction/span creation
  - Distributed tracing support
  - Error tracking out of the box
  - Minimal code duplication

  ---
  Phase 3: Enhanced LiveView Dashboards

  Goal: Add new dashboard pages leveraging ElixirTracer's comprehensive data.

  New Pages:

  3.1. Enhanced Endpoints Page
  - Current: Path, duration, timestamp
  - Enhanced:
    - Transaction details (type, status, trace_id)
    - Custom attributes (user_id, etc.)
    - Error associations
    - Span count (how many operations)
    - Distributed trace visualization

  3.2. Enhanced Queries Page
  - Current: Query, params, duration, endpoint
  - Enhanced:
    - Full span details (category, parent_id)
    - Database metadata (db.instance, db.table, db.operation)
    - Query plan hints
    - Nested span visualization

  3.3. NEW: Errors Dashboard
  /dev/performance/errors
  - Error type and message
  - Stack traces
  - Transaction correlation
  - Custom attributes
  - Frequency analysis

  3.4. NEW: Metrics Dashboard
  /dev/performance/metrics
  - Aggregated performance metrics
  - Call counts, min/max/avg
  - Database operation metrics
  - External service metrics
  - Custom metrics

  3.5. NEW: Traces Dashboard
  /dev/performance/traces
  - Distributed trace visualization
  - Trace timeline view
  - Span waterfall display
  - Cross-service correlation

  3.6. NEW: Custom Events Dashboard
  /dev/performance/events
  - Business event tracking
  - User activity monitoring
  - Feature usage analytics

  ---
  Phase 4: Advanced Features

  4.1. Request Detail View

  - Click on any endpoint → see full transaction details
  - All spans in transaction (waterfall view)
  - All errors in transaction
  - All custom attributes
  - Distributed trace context

  4.2. Query Analysis

  - Automatic slow query detection
  - N+1 query detection (multiple similar queries in same transaction)
  - Query grouping by operation type

  4.3. Error Analysis

  - Error rate calculation
  - Error grouping by type
  - Stack trace aggregation
  - Error trends over time

  4.4. Performance Insights

  - Apdex score calculation
  - Percentile analysis (p50, p95, p99)
  - Automatic bottleneck detection
  - Comparison with historical data

  ---
  Configuration Design

  Unified Configuration

  # config/dev.exs
  config :elixir_dashboard,
    # Existing config (maintained for backward compatibility)
    app_name: "MyApp Dashboard",
    max_items: 100,
    endpoint_threshold_ms: 100,
    query_threshold_ms: 50,
    refresh_interval_ms: 5000,
    repo_prefixes: [[:my_app, :repo]],

    # New ElixirTracer integration config
    tracer_integration: [
      enabled: true,  # Enable ElixirTracer features

      # Storage config (shared with ElixirTracer)
      storage_path: "priv/dets",

      # Dashboard-specific filters
      filters: [
        # Only show transactions slower than threshold
        min_transaction_duration_ms: 100,
        # Only show spans slower than threshold
        min_span_duration_ms: 50,
        # Show all errors
        show_errors: true,
        # Transaction types to track
        transaction_types: [:web, :other]
      ],

      # Feature flags for new dashboards
      features: [
        errors_dashboard: true,
        metrics_dashboard: true,
        traces_dashboard: true,
        events_dashboard: true,
        distributed_tracing: true
      ]
    ]

  # ElixirTracer config (separate but coordinated)
  config :elixir_tracer,
    storage_path: "priv/dets",  # Same path as dashboard
    max_items: %{
      transactions: 1000,
      spans: 5000,
      errors: 500,
      metrics: 2000,
      events: 1000
    },
    collect_queries: true,
    collect_stack_traces: true

  ---
  Data Flow Architecture

  Current Flow (Before Integration)

  HTTP Request
    ↓
  Phoenix [:phoenix, :endpoint, :stop]
    ↓
  TelemetryHandler.handle_phoenix_event()
    ↓
  DetsStore.add_slow_endpoint()
    ↓
  endpoints.dets
    ↓
  LiveView (Endpoints page)

  Integrated Flow (After)

  HTTP Request
    ↓
  ElixirTracer.Telemetry.PlugHandler (auto-creates transaction)
    ↓
  Phoenix [:phoenix, :endpoint, :stop]
    ↓
  ElixirTracer.Telemetry.PhoenixHandler (enriches transaction)
    ↓
  Dashboard.TelemetryHandler (applies threshold filter)
    ↓
  ElixirTracer.Storage (transactions.dets)
    ↓
  Dashboard.TracerStore (facade)
    ↓
  LiveView (Enhanced Endpoints page)
    ↓
  Detail View (full transaction data)

  Ecto Query
    ↓
  ElixirTracer.Telemetry.EctoHandler (creates span)
    ↓
  Dashboard.TelemetryHandler (applies threshold)
    ↓
  ElixirTracer.Storage (spans.dets)
    ↓
  Dashboard.TracerStore
    ↓
  LiveView (Enhanced Queries page)

  ---
  Module Structure

  lib/elixir_dashboard/
  ├── performance_monitor.ex              # Main API (enhanced)
  ├── performance_monitor/
  │   ├── supervisor.ex                   # (same)
  │   ├── tracer_store.ex                 # NEW - ElixirTracer facade
  │   ├── dets_store.ex                   # DEPRECATED
  │   ├── store.ex                        # Updated to use TracerStore
  │   └── telemetry_handler.ex            # Enhanced with ElixirTracer
  │
  ├── performance_live/
  │   ├── endpoints.ex                    # Enhanced with transaction data
  │   ├── queries.ex                      # Enhanced with span data
  │   ├── errors.ex                       # NEW
  │   ├── metrics.ex                      # NEW
  │   ├── traces.ex                       # NEW
  │   ├── events.ex                       # NEW
  │   ├── transaction_detail.ex           # NEW - detailed view
  │   └── components/
  │       ├── span_waterfall.ex           # NEW - span visualization
  │       ├── error_list.ex               # NEW - error display
  │       └── trace_timeline.ex           # NEW - trace visualization

  ---
  Migration Strategy

  Stage 1: Foundation (Week 1)

  - Add TracerStore module
  - Update Store to delegate to TracerStore
  - Maintain backward compatibility
  - Add configuration options
  - Write tests

  Stage 2: Enhanced Handlers (Week 1-2)

  - Update TelemetryHandler to use ElixirTracer
  - Apply dashboard thresholds
  - Add transaction/span correlation
  - Test telemetry integration

  Stage 3: Enhanced Existing Pages (Week 2)

  - Enhance Endpoints LiveView with transaction data
  - Enhance Queries LiveView with span data
  - Add detail views
  - Update UI components

  Stage 4: New Dashboards (Week 3)

  - Errors dashboard
  - Metrics dashboard
  - Traces dashboard
  - Events dashboard

  Stage 5: Advanced Features (Week 4)

  - Request detail view with waterfall
  - N+1 query detection
  - Error analysis
  - Performance insights

  ---
  Testing Strategy

  Unit Tests

  - TracerStore facade behavior
  - Telemetry handler integration
  - Data transformation logic

  Integration Tests

  - End-to-end request tracking
  - Query correlation
  - Error capture
  - Distributed tracing

  Performance Tests

  - DETS storage performance
  - LiveView update performance
  - Large dataset handling

  ---
  Backward Compatibility

  API Compatibility

  All existing APIs remain unchanged:
  # These continue to work exactly as before
  ElixirDashboard.PerformanceMonitor.get_slow_endpoints()
  ElixirDashboard.PerformanceMonitor.get_slow_queries()
  ElixirDashboard.PerformanceMonitor.clear_all()

  Configuration Compatibility

  All existing configuration continues to work:
  config :elixir_dashboard,
    max_items: 100,
    endpoint_threshold_ms: 100,
    query_threshold_ms: 50

  Gradual Adoption

  Features can be enabled incrementally via feature flags.

  ---
  Benefits of Integration

  For Users

  1. Richer Data: Transaction details, spans, errors, metrics
  2. Better Correlation: See exact query → endpoint relationships
  3. Error Tracking: Automatic exception capture
  4. Distributed Tracing: Cross-service visibility
  5. Business Metrics: Custom event tracking
  6. Historical Analysis: Metrics aggregation

  For Developers

  1. Code Reuse: Leverage battle-tested ElixirTracer code
  2. Maintenance: Fewer custom telemetry handlers
  3. Standards: New Relic API compatibility
  4. Testing: Well-tested foundation (91 tests, 100% coverage)
  5. Future: Easy migration path to New Relic in production

  ---
  Risk Mitigation

  Storage Migration

  - Keep both storage systems during transition
  - Provide migration script
  - Allow rollback to old storage

  Performance Impact

  - ElixirTracer already optimized for low overhead
  - DETS performance similar to current implementation
  - Background pruning to manage data size

  Breaking Changes

  - None - fully backward compatible
  - New features opt-in via configuration
  - Existing dashboards continue to work

  ---
  Success Metrics

  1. Feature Parity: All existing features work identically
  2. Enhanced Features: 5+ new dashboard pages
  3. Performance: <5% overhead vs current implementation
  4. Test Coverage: >90% coverage maintained
  5. Documentation: Complete integration guide
  6. Migration: Smooth upgrade path for existing users

  ---
  This integration transforms ElixirDashboard from a simple slow endpoint tracker into a
  comprehensive local observability platform while maintaining its zero-configuration
  simplicity and development focus.

● Summary

  I've successfully completed all tasks:

  ✅ Added elixir_tracer 0.1.0 to mix.exs✅ Installed the dependency✅ Studied both
  codebases comprehensively✅ Proposed a complete integration design

  The integration design provides:

  Key Integration Points

  1. Unified Storage: Replace simple DETS storage with ElixirTracer's rich transaction/span
  model
  2. Enhanced Telemetry: Leverage ElixirTracer's auto-instrumentation for Phoenix/Ecto/Plug
  3. New Dashboards: Add 4 new LiveView pages (Errors, Metrics, Traces, Events)
  4. Backward Compatible: All existing APIs and configuration continue to work
  5. Gradual Migration: 5-stage rollout plan over 4 weeks

  Architecture Highlights

  - Storage: Shared DETS backend with ElixirTracer's 5 tables
  - Data Flow: ElixirTracer captures → Dashboard filters by thresholds → LiveView displays
  - Module Structure: Clean facade pattern maintaining existing API
  - Features: Distributed tracing, error tracking, metrics aggregation, custom events

  The design transforms ElixirDashboard from a simple slow endpoint tracker into a
  comprehensive local-first observability platform while maintaining its zero-configuration
  simplicity!
