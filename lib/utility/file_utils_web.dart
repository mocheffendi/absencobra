// This file intentionally uses `dart:html` for web-only behavior.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openPdfOnWeb(
  Uint8List bytes, {
  String filename = 'file.pdf',
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // revoke after delay
  Future.delayed(
    const Duration(seconds: 2),
    () => html.Url.revokeObjectUrl(url),
  );
}

// Expose savePdfToTemp on web so imports expecting it compile.
Future<String> savePdfToTemp(
  Uint8List bytes, {
  String filenamePrefix = 'file',
}) async {
  await openPdfOnWeb(bytes, filename: '$filenamePrefix.pdf');
  return '';
}

Future<String> saveBytesToCacheAsImage(
  Uint8List bytes, {
  String? filename,
}) async {
  // Not supported on web: persist by returning empty string
  throw UnsupportedError('saveBytesToCacheAsImage is not supported on web');
}
