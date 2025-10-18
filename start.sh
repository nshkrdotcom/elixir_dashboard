#!/bin/bash
# Quick start script for Elixir Dashboard

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   ElixirDashboard v0.2.0                      ║"
echo "║               Performance Monitoring Demo Mode                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "🗄️  Setting up demo database..."
mix ecto.create 2>/dev/null || echo "   Database already exists"
mix ecto.migrate

echo ""
echo "📊 Dashboard URLs:"
echo "   Homepage:        http://localhost:4000"
echo "   Slow Endpoints:  http://localhost:4000/dev/performance/endpoints"
echo "   Slow Queries:    http://localhost:4000/dev/performance/queries"
echo "   LiveDashboard:   http://localhost:4000/dev/dashboard"
echo ""
echo "🧪 Test Endpoints (trigger slow requests):"
echo "   Slow CPU:        http://localhost:4000/demo/slow_cpu?ms=200"
echo "   Slow Query:      http://localhost:4000/demo/slow_query?seconds=0.15"
echo "   Complex Query:   http://localhost:4000/demo/complex_query"
echo "   Multiple:        http://localhost:4000/demo/multiple_queries"
echo ""
echo "⚡ Mix Tasks:"
echo "   mix dashboard.test 20   # Generate 20 test requests"
echo "   mix dashboard.stats     # View current statistics"
echo "   mix dashboard.clear     # Clear all recorded data"
echo ""
echo "💾 Storage: DETS (priv/dets/) - persists across restarts"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "🚀 Starting server..."
echo ""

PHX_SERVER=true iex -S mix phx.server
