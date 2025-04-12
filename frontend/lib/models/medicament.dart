class Medicament {
  final String name;
  final String? usage;
  final String? dosage;
  final String? route;

  Medicament({
    required this.name,
    this.usage,
    this.dosage,
    this.route,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'usage': usage,
      'dosage': dosage,
      'route': route,
    };
  }

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      name: json['name'] ?? '',
      usage: json['usage'],
      dosage: json['dosage'] ?? '',
      route: json['route'],
    );
  }
}
