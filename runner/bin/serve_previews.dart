import 'dart:io';

import 'package:path/path.dart' as p;

/// `dart run bin/serve_previews.dart` — serves the preview folder over
/// HTTP, so a tunnel (or a reverse proxy) can give it a public address.
///
/// Reads `PREVIEW_DIR` and `PREVIEW_PORT` from .env or the environment, the
/// same file the runner reads. The public address of this server is what
/// `PREVIEW_BASE_URL` has to say.
Future<void> main() async {
  final env = <String, String>{..._dotEnv(), ...Platform.environment};
  final root = Directory(env['PREVIEW_DIR'] ?? 'previews').absolute;
  root.createSync(recursive: true);
  final port = int.tryParse(env['PREVIEW_PORT'] ?? '') ?? 8787;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('serving ${root.path} on http://localhost:$port');

  await for (final request in server) {
    try {
      await _serve(request, root);
    } catch (error) {
      stderr.writeln('${request.uri.path}: $error');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }
}

Future<void> _serve(HttpRequest request, Directory root) async {
  final response = request.response;
  if (request.method != 'GET' && request.method != 'HEAD') {
    response.statusCode = HttpStatus.methodNotAllowed;
    return response.close();
  }
  final path = resolve(root.path, request.uri.path);
  var file = path == null ? null : File(path);
  if (file != null && FileSystemEntity.isDirectorySync(file.path)) {
    // A folder without its slash would break the page's relative links.
    if (!request.uri.path.endsWith('/')) {
      response.statusCode = HttpStatus.movedPermanently;
      response.headers.set('location', '${request.uri.path}/');
      return response.close();
    }
    file = File(p.join(file.path, 'index.html'));
  }
  // The top of the folder lists nothing: a preview is found by its link.
  if (file == null || !file.existsSync() || request.uri.path == '/') {
    response.statusCode = HttpStatus.notFound;
    response.write('Not found. A preview is removed after a few days.');
    return response.close();
  }
  response.headers
    ..set('content-type', contentType(file.path))
    ..set('content-length', file.lengthSync())
    ..set('cache-control', 'no-cache');
  if (file.path.endsWith('.apk')) {
    response.headers.set(
      'content-disposition',
      'attachment; filename="${p.basename(file.path)}"',
    );
  }
  if (request.method == 'GET') await response.addStream(file.openRead());
  return response.close();
}

/// The file a request path names under [root], or null when the path
/// tries to leave it.
String? resolve(String root, String requestPath) {
  final String decoded;
  try {
    decoded = Uri.decodeComponent(requestPath);
  } on ArgumentError {
    return null;
  }
  if (decoded.contains('\u0000')) return null;
  final path = p.normalize(
    p.join(root, decoded.replaceFirst(RegExp('^/+'), '')),
  );
  return path == root || p.isWithin(root, path) ? path : null;
}

String contentType(String path) => switch (p.extension(path).toLowerCase()) {
  '.html' => 'text/html; charset=utf-8',
  '.js' || '.mjs' => 'text/javascript; charset=utf-8',
  '.css' => 'text/css; charset=utf-8',
  '.json' || '.map' => 'application/json; charset=utf-8',
  '.wasm' => 'application/wasm',
  '.apk' => 'application/vnd.android.package-archive',
  '.png' => 'image/png',
  '.jpg' || '.jpeg' => 'image/jpeg',
  '.gif' => 'image/gif',
  '.webp' => 'image/webp',
  '.svg' => 'image/svg+xml',
  '.ico' => 'image/x-icon',
  '.ttf' => 'font/ttf',
  '.otf' => 'font/otf',
  '.woff' => 'font/woff',
  '.woff2' => 'font/woff2',
  '.txt' => 'text/plain; charset=utf-8',
  _ => 'application/octet-stream',
};

Map<String, String> _dotEnv() {
  final file = File('.env');
  if (!file.existsSync()) return const {};
  final out = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq == -1) continue;
    out[trimmed.substring(0, eq).trim()] = trimmed
        .substring(eq + 1)
        .replaceAll(RegExp(r'\s+#.*$'), '')
        .trim();
  }
  return out;
}
