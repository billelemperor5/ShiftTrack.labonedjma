// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      firstName: fields[0] as String?,
      lastName: fields[1] as String?,
      companyName: fields[2] as String?,
      logoPath: fields[3] as String?,
      isFirstLaunchDone: fields[4] as bool,
      locale: fields[5] as String,
      workDays: (fields[6] as List).cast<int>(),
      defaultCheckIn: fields[7] as String,
      defaultCheckOut: fields[8] as String,
      themeMode: fields[9] == null ? 'light' : fields[9] as String,
      breakDuration: fields[10] == null ? 30 : fields[10] as int,
      isBreakPaid: fields[11] == null ? false : fields[11] as bool,
      faceCheckinEnabled: fields[12] == null ? false : fields[12] as bool,
      notificationsEnabled: fields[13] == null ? false : fields[13] as bool,
      notificationWorkDays: fields[14] == null
          ? const [6, 7, 1, 2, 3, 4]
          : (fields[14] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.firstName)
      ..writeByte(1)
      ..write(obj.lastName)
      ..writeByte(2)
      ..write(obj.companyName)
      ..writeByte(3)
      ..write(obj.logoPath)
      ..writeByte(4)
      ..write(obj.isFirstLaunchDone)
      ..writeByte(5)
      ..write(obj.locale)
      ..writeByte(6)
      ..write(obj.workDays)
      ..writeByte(7)
      ..write(obj.defaultCheckIn)
      ..writeByte(8)
      ..write(obj.defaultCheckOut)
      ..writeByte(9)
      ..write(obj.themeMode)
      ..writeByte(10)
      ..write(obj.breakDuration)
      ..writeByte(11)
      ..write(obj.isBreakPaid)
      ..writeByte(12)
      ..write(obj.faceCheckinEnabled)
      ..writeByte(13)
      ..write(obj.notificationsEnabled)
      ..writeByte(14)
      ..write(obj.notificationWorkDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
