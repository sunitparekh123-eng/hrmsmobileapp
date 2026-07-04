import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Saves [bytes] to the app's documents directory as [fileName] and opens
/// it with the system viewer. Returns the saved file path.
///
/// This is the **mobile** implementation (Android / iOS). On web the
/// conditional import in `payroll_screen.dart` swaps this out for
/// `file_saver_web.dart` which triggers a browser download instead.
Future<String> saveAndOpenFile(List<int> bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(file.path);
  return file.path;
}
