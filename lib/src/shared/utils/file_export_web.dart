import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use, deprecated_member_use_from_same_package
import 'dart:html' as html;

/// Web implementation: build a blob URL and click an invisible anchor to trigger
/// a browser download. Selected at compile time only when dart:html is available.
/// `subject` is ignored on web (there's no share sheet).
Future<void> exportFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  final blob = html.Blob(<dynamic>[Uint8List.fromList(bytes)], mimeType);
  final url  = html.Url.createObjectUrlFromBlob(blob);
  (html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click());
  html.Url.revokeObjectUrl(url);
}
