#!/usr/bin/env bash
# Builds the landing pages and zips the upload folder for Hostinger's file
# manager (public_html of apprelease.store).
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tool/build_landing.py
mkdir -p dist
STAMP="$(date +%Y%m%d)"
rm -f "dist/apprelease-landing-$STAMP.zip"
( cd landing && zip -qr "../dist/apprelease-landing-$STAMP.zip" . -x '.DS_Store' )
echo "dist/apprelease-landing-$STAMP.zip"
