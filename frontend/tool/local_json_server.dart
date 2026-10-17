import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args[0]) ?? 8080 : 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('================================================================');
  print('  EduPulse Local JSON Sync Server running on http://127.0.0.1:$port');
  print('  Allows Flutter Web to persist mutations directly to disk JSON files.');
  print('================================================================');

  await for (final HttpRequest request in server) {
    // Add CORS headers so web clients on any local port can communicate
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Origin, Accept');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    final path = request.uri.path;
    try {
      if (path == '/api/health') {
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}));
        await request.response.close();
        continue;
      }

      if (path == '/api/data') {
        final filePath = request.uri.queryParameters['file'];
        if (filePath == null || filePath.isEmpty) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write(jsonEncode({'error': 'Missing "file" query parameter'}));
          await request.response.close();
          continue;
        }

        // Sanitize path to prevent directory traversal
        final cleanPath = filePath.replaceAll(r'\', '/').replaceAll('..', '');
        final file = File(cleanPath.startsWith('assets/') ? cleanPath : 'assets/data/$cleanPath');

        if (request.method == 'GET') {
          if (!file.existsSync()) {
            request.response
              ..statusCode = HttpStatus.notFound
              ..write(jsonEncode({'error': 'File not found: ${file.path}'}));
            await request.response.close();
            continue;
          }

          final content = file.readAsStringSync();
          request.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.ok
            ..write(content);
          await request.response.close();
          continue;
        } else if (request.method == 'POST' || request.method == 'PUT') {
          final body = await utf8.decoder.bind(request).join();
          final parsed = jsonDecode(body);
          const encoder = JsonEncoder.withIndent('  ');
          final formatted = encoder.convert(parsed);

          if (!file.parent.existsSync()) {
            file.parent.createSync(recursive: true);
          }
          file.writeAsStringSync(formatted);
          print('[SYNC] Successfully updated disk JSON: ${file.path} (${formatted.length} bytes)');

          request.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'status': 'saved', 'path': file.path, 'size': formatted.length}));
          await request.response.close();
          continue;
        }
      }

      // Default 404
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'error': 'Endpoint not found'}));
      await request.response.close();
    } catch (e, st) {
      print('[ERROR] Server exception: $e\n$st');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }
}
