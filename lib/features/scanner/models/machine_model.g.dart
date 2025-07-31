// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MachineModelAdapter extends TypeAdapter<MachineModel> {
  @override
  final int typeId = 3;

  @override
  MachineModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MachineModel(
      id: fields[0] as String,
      name: fields[1] as String,
      reference: fields[2] as String,
      department: fields[3] as String,
      location: fields[4] as String,
      description: fields[5] as String?,
      manufacturer: fields[6] as String?,
      model: fields[7] as String?,
      serialNumber: fields[8] as String?,
      installationDate: fields[9] as DateTime?,
      nextMaintenanceDate: fields[10] as DateTime?,
      status: fields[11] as String,
      additionalData: (fields[12] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MachineModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.reference)
      ..writeByte(3)
      ..write(obj.department)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.manufacturer)
      ..writeByte(7)
      ..write(obj.model)
      ..writeByte(8)
      ..write(obj.serialNumber)
      ..writeByte(9)
      ..write(obj.installationDate)
      ..writeByte(10)
      ..write(obj.nextMaintenanceDate)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.additionalData)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachineModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
