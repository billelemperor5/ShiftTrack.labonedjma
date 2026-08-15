// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<String> saveImageHelper(String sourcePath) async {
  if (sourcePath.startsWith('blob:')) {
    try {
      final completer = Completer<String>();
      final xhr = html.HttpRequest()
        ..open('GET', sourcePath)
        ..responseType = 'blob';
      
      xhr.onLoad.listen((_) {
        final blob = xhr.response as html.Blob;
        final reader = html.FileReader();
        reader.onLoadEnd.listen((_) {
          completer.complete(reader.result as String);
        });
        reader.readAsDataUrl(blob);
      });
      
      xhr.onError.listen((e) {
        completer.complete(sourcePath); // Fallback to original blob URL
      });
      
      xhr.send();
      return completer.future;
    } catch (_) {
      return sourcePath;
    }
  }
  return sourcePath;
}
