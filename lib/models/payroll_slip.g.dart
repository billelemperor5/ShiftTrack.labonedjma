// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_slip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PayrollSlipAdapter extends TypeAdapter<PayrollSlip> {
  @override
  final int typeId = 4;

  @override
  PayrollSlip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PayrollSlip(
      date: fields[0] as DateTime,
      imagePath: fields[1] as String,
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PayrollSlip obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollSlipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
