class PatientDirectoryEntry {
  const PatientDirectoryEntry({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory PatientDirectoryEntry.fromJson(Map<String, dynamic> json) {
    final first = json['firstName']?.toString().trim() ?? '';
    final last = json['lastName']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    final email = json['email']?.toString().trim() ?? '';
    final username = json['username']?.toString().trim() ?? '';
    final attributes = json['attributes'] is Map
        ? (json['attributes'] as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};

    String? firstValue(dynamic value) {
      if (value is List && value.isNotEmpty) {
        final text = value.first?.toString().trim() ?? '';
        return text.isEmpty ? null : text;
      }
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return PatientDirectoryEntry(
      id: json['id']?.toString() ?? '',
      name: combined.isNotEmpty
          ? combined
          : username.isNotEmpty
              ? username
              : email,
      email: email,
      phone: firstValue(attributes['phone']),
    );
  }
}
