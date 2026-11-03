import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> saveFilePlatform(String filename, String content, {String mimeType = 'text/csv'}) async {
  try {
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  } catch (_) {
    return null;
  }
}

