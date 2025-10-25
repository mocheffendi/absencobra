import 'dart:io';
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart' as path_provider;

Future<String> savePdfToTemp(
  Uint8List bytes, {
  String filenamePrefix = 'file',
}) async {
  final dir = await path_provider.getTemporaryDirectory();
  final file = File(
    '${dir.path}/${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String> saveBytesToCacheAsImage(
  Uint8List bytes, {
  String? filename,
}) async {
  final dir = await path_provider.getTemporaryDirectory();
  final name =
      filename ?? 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

// No-op for web import compatibility
Future<void> openPdfOnWeb(
  Uint8List bytes, {
  String filename = 'file.pdf',
}) async {
  throw UnsupportedError('openPdfOnWeb is not supported on this platform');
}
