import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tabs/flow_ui.dart';
import 'csv_export_helper_stub.dart'
    if (dart.library.html) 'csv_export_helper_web.dart'
    if (dart.library.io) 'csv_export_helper_io.dart';

/// Exports and triggers native download / saving of a file.
/// If file system saving is unavailable, falls back to copying to clipboard.
Future<void> exportAndDownloadFile(
  BuildContext context, {
  required String filename,
  required String content,
  String mimeType = 'text/csv',
  String successMessage = 'Exported successfully',
}) async {
  final path = await saveFilePlatform(filename, content, mimeType: mimeType);
  if (context.mounted) {
    if (path != null) {
      flowSnack(context, '$successMessage ($filename)');
    } else {
      await Clipboard.setData(ClipboardData(text: content));
      flowSnack(context, '$filename content copied to clipboard.');
    }
  }
}

