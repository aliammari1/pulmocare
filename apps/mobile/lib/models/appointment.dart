class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.providerType,
    required this.appointmentType,
    required this.appointmentDate,
    required this.durationMinutes,
    required this.status,
    this.reason,
    this.notes,
    this.virtual = false,
    this.meetingLink,
  });

  final String id;
  final String patientId;
  final String providerId;
  final String providerType;
  final String appointmentType;
  final DateTime appointmentDate;
  final int durationMinutes;
  final String status;
  final String? reason;
  final String? notes;
  final bool virtual;
  final String? meetingLink;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: (json['appointment_id'] ?? json['id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      providerId: (json['provider_id'] ?? '').toString(),
      providerType: (json['provider_type'] ?? '').toString(),
      appointmentType: (json['appointment_type'] ?? 'consultation').toString(),
      appointmentDate:
          DateTime.tryParse(json['appointment_date']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      durationMinutes: _asInt(json['duration_minutes'], fallback: 30),
      status: (json['status'] ?? 'pending').toString(),
      reason: _nullableString(json['reason']),
      notes: _nullableString(json['notes']),
      virtual: json['virtual'] == true,
      meetingLink: _nullableString(json['meeting_link']),
    );
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
