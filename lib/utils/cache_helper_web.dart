// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> clearCacheAndReloadHelper() async {
  try {
    // 1. Clear CacheStorage
    if (html.window.caches != null) {
      final keys = await html.window.caches!.keys();
      for (final key in keys) {
        await html.window.caches!.delete(key);
      }
    }
  } catch (_) {}

  try {
    // 2. Unregister ServiceWorkers
    final sw = html.window.navigator.serviceWorker;
    if (sw != null) {
      final registrations = await sw.getRegistrations();
      for (final reg in registrations) {
        await reg.unregister();
      }
    }
  } catch (_) {}

  try {
    // 3. Mark version in localStorage
    html.window.localStorage['shifttrack_app_version'] = '3.0.2+32';
  } catch (_) {}

  // 4. Force reload page
  try {
    html.window.location.reload();
  } catch (_) {
    html.window.location.href = html.window.location.href;
  }
}
