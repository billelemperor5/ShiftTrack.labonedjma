import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider getImageProviderHelper(String path) {
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  return FileImage(File(path));
}

Widget getImageWidgetHelper(String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  Widget? errorWidget,
}) {
  final fallback = errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey);
  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}

bool existsHelper(String? path) {
  if (path == null || path.isEmpty) return false;
  if (path.startsWith('assets/')) return true;
  return File(path).existsSync();
}
