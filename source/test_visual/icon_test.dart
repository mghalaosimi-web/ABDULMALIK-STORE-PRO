import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  for (final path in [
    'assets/icon/app_icon.png',
    'assets/icon/app_icon_foreground.png',
  ]) {
    test('$path is a valid official logo image', () {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 512);
      expect(decoded.height, 512);
      final nonWhite = decoded
          .where((pixel) => pixel.r < 235 || pixel.g < 235 || pixel.b < 235)
          .length;
      expect(nonWhite, greaterThan(512 * 512 * 0.05));
      if (path.endsWith('app_icon_foreground.png')) {
        expect(
          decoded.getPixel(0, 0).a,
          0,
          reason: 'Adaptive icon foreground must preserve transparency.',
        );
        expect(decoded.getPixel(256, 120).a, greaterThan(0));
      }
    });
  }
}
