import 'cache_helper_stub.dart'
    if (dart.library.html) 'cache_helper_web.dart';

class CacheHelper {
  static Future<void> clearCacheAndReload() async {
    await clearCacheAndReloadHelper();
  }
}
