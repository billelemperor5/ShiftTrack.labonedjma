import 'dart:typed_data';
import 'file_saver_stub.dart'
  if (dart.library.html) 'file_saver_web.dart'
  if (dart.library.io) 'file_saver_mobile.dart';

class FileSaver {
  static Future<void> saveAndShareFile(Uint8List bytes, String filename) async {
    await saveAndShareFileHelper(bytes, filename);
  }
}
