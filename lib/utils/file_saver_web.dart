// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download of [bytes] as [fileName]. Returns an empty
/// string (no file path on web — the browser handles the download).
///
/// This is the **web** implementation. It is only compiled when
/// `dart.library.html` is available (i.e. during a `flutter build web`).
/// On mobile platforms the conditional import resolves to `file_saver.dart`
/// instead, which uses `dart:io` + `path_provider` + `open_filex`.
Future<String> saveAndOpenFile(List<int> bytes, String fileName) async {
  final blob = html.Blob(
    [Uint8List.fromList(bytes)],
    'application/pdf',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return '';
}
