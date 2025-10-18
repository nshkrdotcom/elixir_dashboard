# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-XX

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

[0.1.0]: https://github.com/yourorg/elixir_dashboard/releases/tag/v0.1.0
