import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> saveImageHelper(String sourcePath) async {
  final appDir = await getApplicationDocumentsDirectory();
  final uploadDir = Directory(p.join(appDir.path, 'uploads'));
  if (!uploadDir.existsSync()) {
    uploadDir.createSync(recursive: true);
  }

  final filename = p.basename(sourcePath);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final destPath = p.join(uploadDir.path, '${timestamp}_$filename');

  final sourceFile = File(sourcePath);
  await sourceFile.copy(destPath);

  return destPath;
}
