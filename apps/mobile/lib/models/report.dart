class Report {
  const Report({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.additionalData,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? additionalData;

  factory Report.fromJson(Map<String, dynamic> json) {
    final knownKeys = {
      '_id',
      'id',
      'report_id',
      'patient_id',
      'doctor_id',
      'provider_id',
      'title',
      'content',
      'findings',
      'impression',
      'created_at',
      'updated_at',
      'additional_data',
    };

    final extras = <String, dynamic>{};
    final explicitExtras = json['additional_data'];
    if (explicitExtras is Map) {
      extras.addAll(
        explicitExtras.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    for (final entry in json.entries) {
      if (!knownKeys.contains(entry.key)) extras[entry.key] = entry.value;
    }

    final findings = json['findings']?.toString().trim() ?? '';
    final impression = json['impression']?.toString().trim() ?? '';
    final rawContent = json['content']?.toString().trim() ?? '';
    final content = rawContent.isNotEmpty
        ? rawContent
        : [
            if (findings.isNotEmpty) 'Findings\n$findings',
            if (impression.isNotEmpty) 'Impression\n$impression',
          ].join('\n\n');

    return Report(
      id: (json['_id'] ?? json['id'] ?? json['report_id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['provider_id'] ?? '').toString(),
      title: _nonEmpty(json['title']) ?? 'Medical report',
      content: content,
      createdAt:
          _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _date(json['updated_at']),
      additionalData: extras.isEmpty ? null : extras,
    );
  }

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'doctor_id': doctorId,
    'title': title,
    'content': content,
    if (additionalData != null) 'additional_data': additionalData,
  };

  static DateTime? _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
