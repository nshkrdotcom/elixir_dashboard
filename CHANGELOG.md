# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-01-17

### Added
- **DETS Persistent Storage** - Data now persists across server restarts
  - Stored in `priv/dets/endpoints.dets` and `priv/dets/queries.dets`
  - Automatic pruning to maintain max_items limit
  - `get_stats/0` API for storage inspection
- **Complete Demo System** with real database integration
  - PostgreSQL database with Ecto
  - Demo tables: `demo_users` (1,000 records) and `demo_posts` (5,000 records)
  - Automatic database setup and seeding via `./start.sh`
- **Mix CLI Commands** for testing and inspection:
  - `mix dashboard.test [count]` - Generate HTTP test requests
  - `mix dashboard.stats` - View DETS statistics and top slow items
  - `mix dashboard.slow_query [seconds]` - Execute slow query directly
  - `mix dashboard.clear` - Clear all recorded data
- **Real Slow Endpoints** for demo/testing:
  - `/demo/slow_cpu?ms=N` - CPU delay using Process.sleep
  - `/demo/slow_query?seconds=N` - Database delay using pg_sleep()
  - `/demo/complex_query` - Complex JOIN with aggregation
  - `/demo/multiple_queries` - Multiple correlated queries showing request correlation
  - `/demo/random_slow` - Random delays for varied testing
- **Configurable App Name** - Set custom app name in UI
  - Configure via `config :elixir_dashboard, :app_name, "MyApp"`
  - Appears in page titles, navigation, and dashboard headers
- **Enhanced UI** with dev mode indicators
  - Prominent "Demo Mode Active" banner on homepage
  - Clickable test endpoint links
  - Mix command examples in UI
  - DETS storage location display
- **Improved Developer Experience**
  - `./start.sh` now automatically creates database and runs migrations
  - Beautiful ASCII banner with all URLs and commands
  - Clear instructions for populating empty dashboards
  - Comprehensive README section explaining demo mode

### Changed
- Storage backend changed from in-memory GenServer to DETS for persistence
- Demo app now includes Ecto and Postgrex (dev/test only)
- Mix aliases added: `ecto.setup`, `ecto.reset`

### Fixed
- Ecto query syntax in demo controller (use raw SQL instead of query builder)
- Supervisor now correctly uses DetsStore with proper child_spec
- All compilation warnings resolved

## [0.1.0] - 2025-01-17

### Added
- Initial release of ElixirDashboard
- Real-time performance monitoring for Phoenix endpoints
- SQL query tracking with Ecto integration
- LiveView dashboards for endpoints and queries
- In-memory GenServer-based data storage
- Configurable thresholds for endpoint and query capture
- Auto-refresh functionality (configurable interval)
- Color-coded performance indicators
- Request/query correlation using process dictionary
- Development-only telemetry handlers
- Standalone demo application
- Library mode for integration into existing Phoenix apps
- Comprehensive documentation and integration guide

### Features
- Track slow API endpoints (default: >100ms)
- Monitor slow database queries (default: >50ms)
- See which endpoints triggered specific queries
- Keep top N slowest items (configurable, default: 100)
- Auto-refresh every N seconds (configurable, default: 5000ms)
- Clear data with one click
- Zero configuration required (works with sensible defaults)
- Compatible with New Relic Elixir Agent (non-interfering)

[0.2.0]: https://github.com/nshkrdotcom/elixir_dashboard/releases/tag/v0.2.0
[0.1.0]: https://github.com/nshkrdotcom/elixir_dashboard/releases/tag/v0.1.0
