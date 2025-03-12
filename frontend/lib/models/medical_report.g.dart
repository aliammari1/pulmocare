// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicalReportAdapter extends TypeAdapter<MedicalReport> {
  @override
  final int typeId = 0;

  @override
  MedicalReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicalReport(
      id: fields[0] as String,
      patientName: fields[1] as String,
      date: fields[2] as DateTime,
      diagnosis: fields[3] as String,
      symptoms: fields[4] as String,
      prescription: fields[5] as String,
      attachments: (fields[6] as List).cast<String>(),
      doctorNotes: fields[7] as String,
      isHandwritten: fields[8] as bool,
      isDictated: fields[9] as bool,
      patientId: fields[10] as String,
      vitalSigns: (fields[11] as Map).cast<String, String>(),
      isUrgent: fields[12] as bool,
      doctorId: fields[13] as String,
      createdAt: fields[14] as DateTime?,
      lastModified: fields[15] as DateTime?,
      status: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MedicalReport obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.diagnosis)
      ..writeByte(4)
      ..write(obj.symptoms)
      ..writeByte(5)
      ..write(obj.prescription)
      ..writeByte(6)
      ..write(obj.attachments)
      ..writeByte(7)
      ..write(obj.doctorNotes)
      ..writeByte(8)
      ..write(obj.isHandwritten)
      ..writeByte(9)
      ..write(obj.isDictated)
      ..writeByte(10)
      ..write(obj.patientId)
      ..writeByte(11)
      ..write(obj.vitalSigns)
      ..writeByte(12)
      ..write(obj.isUrgent)
      ..writeByte(13)
      ..write(obj.doctorId)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.lastModified)
      ..writeByte(16)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
