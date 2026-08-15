import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// In-memory cache for decoded base64 bytes to avoid redundant CPU decoding on every build
final Map<String, Uint8List> _base64Cache = {};

ImageProvider getImageProviderHelper(String path) {
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  if (path.startsWith('data:image/')) {
    final commaIndex = path.indexOf(',');
    if (commaIndex != -1) {
      try {
        final base64Str = path.substring(commaIndex + 1);
        Uint8List bytes;
        if (_base64Cache.containsKey(base64Str)) {
          bytes = _base64Cache[base64Str]!;
        } else {
          bytes = base64.decode(base64Str);
          _base64Cache[base64Str] = bytes;
        }
        return MemoryImage(bytes);
      } catch (_) {}
    }
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return AssetImage(path);
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
  if (path.startsWith('data:image/')) {
    final commaIndex = path.indexOf(',');
    if (commaIndex != -1) {
      try {
        final base64Str = path.substring(commaIndex + 1);
        Uint8List bytes;
        if (_base64Cache.containsKey(base64Str)) {
          bytes = _base64Cache[base64Str]!;
        } else {
          bytes = base64.decode(base64Str);
          _base64Cache[base64Str] = bytes;
        }
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      } catch (_) {}
    }
  }
  return Image.network(
    path,
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}

bool existsHelper(String? path) {
  return path != null && path.isNotEmpty;
}
