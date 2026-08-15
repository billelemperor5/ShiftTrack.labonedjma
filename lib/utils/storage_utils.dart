import 'storage_utils_stub.dart'
  if (dart.library.html) 'storage_utils_web.dart'
  if (dart.library.io) 'storage_utils_mobile.dart';

class StorageUtils {
  static Future<String> saveImage(String sourcePath) async {
    return saveImageHelper(sourcePath);
  }
}
