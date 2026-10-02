import 'package:hive/hive.dart';

part 'water_log.g.dart';

@HiveType(typeId: 1)
class WaterLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int amountMl;

  @HiveField(2)
  DateTime timestamp;

  WaterLog({
    required this.id,
    required this.amountMl,
    required this.timestamp,
  });
}
