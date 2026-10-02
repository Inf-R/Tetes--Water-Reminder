// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 0;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      weightKg: fields[0] as double,
      dailyTargetMl: fields[1] as int,
      wakeTimeHour: fields[2] as int,
      wakeTimeMinute: fields[3] as int,
      sleepTimeHour: fields[4] as int,
      sleepTimeMinute: fields[5] as int,
      reminderIntervalMinutes: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.weightKg)
      ..writeByte(1)
      ..write(obj.dailyTargetMl)
      ..writeByte(2)
      ..write(obj.wakeTimeHour)
      ..writeByte(3)
      ..write(obj.wakeTimeMinute)
      ..writeByte(4)
      ..write(obj.sleepTimeHour)
      ..writeByte(5)
      ..write(obj.sleepTimeMinute)
      ..writeByte(6)
      ..write(obj.reminderIntervalMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
