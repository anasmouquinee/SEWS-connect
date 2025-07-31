// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MachineDataAdapter extends TypeAdapter<MachineData> {
  @override
  final int typeId = 0;

  @override
  MachineData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MachineData(
      id: fields[0] as String,
      machineName: fields[1] as String,
      department: fields[2] as String,
      location: fields[3] as String,
      machineType: fields[4] as String,
      manufacturer: fields[5] as String,
      model: fields[6] as String,
      serialNumber: fields[7] as String,
      installationDate: fields[8] as String,
      status: fields[9] as String,
      qrCode: fields[10] as String,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      description: fields[13] as String?,
      maintenanceSchedule: fields[14] as String?,
      lastMaintenanceDate: fields[15] as String?,
      nextMaintenanceDate: fields[16] as String?,
      operatingInstructions: (fields[17] as List?)?.cast<String>(),
      safetyNotes: (fields[18] as List?)?.cast<String>(),
      imageUrl: fields[19] as String?,
      specifications: (fields[20] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, MachineData obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.machineName)
      ..writeByte(2)
      ..write(obj.department)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.machineType)
      ..writeByte(5)
      ..write(obj.manufacturer)
      ..writeByte(6)
      ..write(obj.model)
      ..writeByte(7)
      ..write(obj.serialNumber)
      ..writeByte(8)
      ..write(obj.installationDate)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.qrCode)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.description)
      ..writeByte(14)
      ..write(obj.maintenanceSchedule)
      ..writeByte(15)
      ..write(obj.lastMaintenanceDate)
      ..writeByte(16)
      ..write(obj.nextMaintenanceDate)
      ..writeByte(17)
      ..write(obj.operatingInstructions)
      ..writeByte(18)
      ..write(obj.safetyNotes)
      ..writeByte(19)
      ..write(obj.imageUrl)
      ..writeByte(20)
      ..write(obj.specifications);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachineDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
