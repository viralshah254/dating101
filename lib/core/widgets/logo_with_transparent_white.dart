import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Loads an asset image and makes white / near-white pixels transparent,
/// then displays the result. Use for logos that have an opaque white
/// background in the source file.
class LogoWithTransparentWhite extends StatelessWidget {
  const LogoWithTransparentWhite({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.whiteThreshold = 248,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Pixels with R,G,B all >= this value (0-255) are made transparent.
  final int whiteThreshold;

  static final Map<String, Uint8List> _cache = {};

  Future<Uint8List?> _loadAndProcess(BuildContext context) async {
    final cacheKey = '$assetPath-$whiteThreshold';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];
    try {
      final bundle = DefaultAssetBundle.of(context);
      final data = await bundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final p = image.getPixel(x, y);
          final r = p.r.toInt();
          final g = p.g.toInt();
          final b = p.b.toInt();
          if (r >= whiteThreshold &&
              g >= whiteThreshold &&
              b >= whiteThreshold) {
            image.setPixelRgba(x, y, r, g, b, 0);
          }
        }
      }

      final out = Uint8List.fromList(img.encodePng(image));
      _cache[cacheKey] = out;
      return out;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadAndProcess(context),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
          );
        }
        return Image.asset(assetPath, width: width, height: height, fit: fit);
      },
    );
  }
}
