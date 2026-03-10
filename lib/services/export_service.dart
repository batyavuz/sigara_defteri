import 'dart:convert' show utf8;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sigara_defteri/services/storage_service.dart';

/// Tüm kayıtları CSV olarak dışa aktarır ve paylaşım menüsünü açar.
/// [onError] hata mesajı döner.
Future<String?> exportEntriesToCsvAndShare() async {
  try {
    final entries = StorageService.instance.getAllEntries();
    const csvHeader =
        'Tarih,Saat,Tür,Adet,Tetikleyici,Marka,Not,Paket Fiyatı';
    final rows = <String>[csvHeader];

    for (final e in entries) {
      final date = '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
      final time = '${e.createdAt.hour.toString().padLeft(2, '0')}:${e.createdAt.minute.toString().padLeft(2, '0')}';
      final trigger = (e.trigger ?? '').replaceAll(',', ' ');
      final brand = (e.brand ?? '').replaceAll(',', ' ');
      final note = (e.note ?? '').replaceAll(',', ' ').replaceAll('\n', ' ');
      final price = e.pricePerPack?.toStringAsFixed(2) ?? '';
      rows.add('$date,$time,${e.type},${e.amount},$trigger,$brand,$note,$price');
    }

    final csv = rows.join('\n');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sigara_defteri_export.csv');
    await file.writeAsString(csv, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Sigara Defteri — veri dışa aktarımı',
      text: 'Sigara Defteri kayıtlarım.',
    );
    return null;
  } catch (e) {
    return e.toString();
  }
}
