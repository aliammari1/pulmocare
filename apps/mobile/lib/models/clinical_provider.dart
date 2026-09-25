class ClinicalProvider {
  const ClinicalProvider({
    required this.id,
    required this.name,
    required this.providerType,
    this.specialty,
    this.hospital,
  });

  final String id;
  final String name;
  final String providerType;
  final String? specialty;
  final String? hospital;

  factory ClinicalProvider.fromJson(Map<String, dynamic> json) {
    String? optional(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return ClinicalProvider(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Clinical provider').toString(),
      providerType: (json['provider_type'] ?? 'doctor').toString(),
      specialty: optional(json['specialty']),
      hospital: optional(json['hospital']),
    );
  }
}
