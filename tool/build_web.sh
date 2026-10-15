#!/usr/bin/env bash
# Builds the console for publish.apprelease.store so a browser can never
# serve a stale version.
#
# Flutter emits fixed file names (main.dart.js), so a proxy or a browser that
# cached one keeps it until it expires. This renames the payload per build and
# rewrites the references, so every deploy is a new URL nobody has cached.
#
#   tool/build_web.sh                       # demo data
#   SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… tool/build_web.sh
set -euo pipefail

cd "$(dirname "$0")/.."

rm -rf build/web

DEFINES=()
if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  DEFINES+=(--dart-define="SUPABASE_URL=$SUPABASE_URL" --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY")
else
  echo "no SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY — building with demo data"
fi

# --no-web-resources-cdn keeps CanvasKit on our own host, so a network that
# blocks Google does not leave the app on its splash.
flutter build web --release --base-href=/ --pwa-strategy=none \
  --no-web-resources-cdn "${DEFINES[@]}"

cd build/web

STAMP="$(date +%Y%m%d%H%M%S)"
mv main.dart.js "main.$STAMP.js"
perl -pi -e "s/main\.dart\.js/main.$STAMP.js/g" flutter_bootstrap.js
perl -pi -e "s/flutter_bootstrap\.js/flutter_bootstrap.js?v=$STAMP/g" index.html

cat > .htaccess <<HT
# AppRelease console (publish.apprelease.store)
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

DirectoryIndex index.html

RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.html [L]

# Hostinger serves .wasm as text/plain, and CanvasKit refuses that.
AddType application/wasm .wasm
AddType text/javascript .js
AddType application/json .json
AddType font/woff2 .woff2
AddType font/ttf .ttf
AddType image/svg+xml .svg

<IfModule mod_headers.c>
  Header always set X-Content-Type-Options "nosniff"
  Header always set Referrer-Policy "strict-origin-when-cross-origin"
  <FilesMatch "(index\.html|flutter_bootstrap\.js|flutter\.js|version\.json|manifest\.json)\$">
    Header set Cache-Control "no-cache, no-store, must-revalidate"
  </FilesMatch>
</IfModule>

<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/css application/javascript application/json image/svg+xml
</IfModule>
HT

mkdir -p ../../dist
zip -qr "../../dist/apprelease-console-$STAMP.zip" .
echo "built with stamp $STAMP → dist/apprelease-console-$STAMP.zip"
