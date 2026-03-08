import 'package:hive/hive.dart';

part 'smoke_entry.g.dart';

@HiveType(typeId: 0)
class SmokeEntry extends HiveObject {
  @HiveField(0)
  late DateTime createdAt;

  @HiveField(1)
  late int amount;

  @HiveField(2)
  late String type; // sigara | vape | puro | nargile

  @HiveField(3)
  String? trigger;

  @HiveField(4)
  String? note;

  @HiveField(5)
  double? pricePerPack;

  @HiveField(6)
  late String id;

  SmokeEntry({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.type,
    this.trigger,
    this.note,
    this.pricePerPack,
  });
}
