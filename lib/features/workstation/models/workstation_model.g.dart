// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workstation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkstationModelAdapter extends TypeAdapter<WorkstationModel> {
  @override
  final int typeId = 0;

  @override
  WorkstationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkstationModel(
      workStation: fields[0] as String,
      project: fields[1] as String,
      quantity: fields[2] as int,
      workstepProgress: fields[3] as String,
      micrographProgress: fields[4] as String,
      priority: fields[5] as String,
      prototyping: fields[6] as String,
      lockedLookReason: fields[7] as String,
      goodParts: fields[8] as String,
      creationDate: fields[9] as DateTime?,
      targetDate: fields[10] as DateTime?,
      plannedStartDate: fields[11] as DateTime?,
      plannedEndDate: fields[12] as DateTime?,
      actualStartDate: fields[13] as DateTime?,
      actualEndDate: fields[14] as DateTime?,
      plannedSetupDuration: fields[15] as double?,
      plannedProduction: fields[16] as double?,
      qrCode: fields[17] as String?,
      department: fields[18] as String,
      status: fields[19] as String,
      lastUpdated: fields[20] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkstationModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.workStation)
      ..writeByte(1)
      ..write(obj.project)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.workstepProgress)
      ..writeByte(4)
      ..write(obj.micrographProgress)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.prototyping)
      ..writeByte(7)
      ..write(obj.lockedLookReason)
      ..writeByte(8)
      ..write(obj.goodParts)
      ..writeByte(9)
      ..write(obj.creationDate)
      ..writeByte(10)
      ..write(obj.targetDate)
      ..writeByte(11)
      ..write(obj.plannedStartDate)
      ..writeByte(12)
      ..write(obj.plannedEndDate)
      ..writeByte(13)
      ..write(obj.actualStartDate)
      ..writeByte(14)
      ..write(obj.actualEndDate)
      ..writeByte(15)
      ..write(obj.plannedSetupDuration)
      ..writeByte(16)
      ..write(obj.plannedProduction)
      ..writeByte(17)
      ..write(obj.qrCode)
      ..writeByte(18)
      ..write(obj.department)
      ..writeByte(19)
      ..write(obj.status)
      ..writeByte(20)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkstationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
