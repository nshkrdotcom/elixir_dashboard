#!/bin/bash
# Quick start script for Elixir Dashboard

echo "Starting Elixir Dashboard..."
echo "================================"
echo ""
echo "The dashboard will be available at:"
echo "  - Homepage:        http://localhost:4000"
echo "  - Slow Endpoints:  http://localhost:4000/dev/performance/endpoints"
echo "  - Slow Queries:    http://localhost:4000/dev/performance/queries"
echo "  - LiveDashboard:   http://localhost:4000/dev/dashboard"
echo ""
echo "================================"
echo ""

PHX_SERVER=true iex -S mix phx.server
