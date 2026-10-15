#!/usr/bin/env bash
# Rebuilds the landing pages and serves them exactly as Hostinger will:
# folders as URLs, so /pricing/ resolves to pricing/index.html.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tool/build_landing.py
cd landing
echo "Landing on http://localhost:8080 — Ctrl+C to stop"
python3 -m http.server 8080
