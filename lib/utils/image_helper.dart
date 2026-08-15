import 'package:flutter/material.dart';
import 'image_helper_stub.dart'
  if (dart.library.html) 'image_helper_web.dart'
  if (dart.library.io) 'image_helper_mobile.dart';
import 'official_logo_data.dart';

class AppImageHelper {
  static const String officialLogo = 'assets/images/official_logo.jpg';

  static ImageProvider get officialLogoProvider => kOfficialLogoImage;

  static ImageProvider getImageProvider(String path) {
    if (path.isEmpty || path == officialLogo || path.contains('official_logo')) {
      return kOfficialLogoImage;
    }
    return getImageProviderHelper(path);
  }

  static Widget getImageWidget(String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
    Widget? errorWidget,
  }) {
    if (path.isEmpty || path == officialLogo || path.contains('official_logo')) {
      return Image.memory(
        kOfficialLogoBytes,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );
    }
    return getImageWidgetHelper(
      path,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorWidget: errorWidget,
    );
  }

  static bool exists(String? path) {
    if (path == null || path.isEmpty) return false;
    return existsHelper(path);
  }
}
