class MedicalReport {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final Map<String, dynamic>? metadata;

  MedicalReport({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.metadata,
  });

  factory MedicalReport.fromJson(Map<String, dynamic> json) {
    return MedicalReport(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'metadata': metadata,
      };
}
