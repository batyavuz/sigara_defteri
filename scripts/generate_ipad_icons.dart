// One-off script: 1024.png'den iPad ikonları (76, 152, 167) üretir.
// Çalıştırma: dart run scripts/generate_ipad_icons.dart
// (Proje kökünden)

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final root = Directory.current.path;
  final appIconSet = '$root/ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final src = File('$appIconSet/1024.png');
  if (!src.existsSync()) {
    print('Hata: $appIconSet/1024.png bulunamadı.');
    exit(1);
  }
  final bytes = src.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Hata: 1024.png decode edilemedi.');
    exit(1);
  }

  for (final size in [76, 152, 167]) {
    final resized = img.copyResize(image, width: size, height: size);
    final out = File('$appIconSet/$size.png');
    out.writeAsBytesSync(img.encodePng(resized));
    print('Yazıldı: ${out.path}');
  }
  print('iPad ikonları üretildi (76.png, 152.png, 167.png).');
}
