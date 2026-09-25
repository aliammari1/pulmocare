import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/DioClient.dart';

class PatientsView extends StatefulWidget {
  const PatientsView({super.key});

  @override
  State<PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<PatientsView> {
  final Dio _dio = DioHttpClient().dio;
  final TextEditingController _search = TextEditingController();

  List<_PatientSummary> _patients = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _dio.get<List<dynamic>>(
        'auth/users',
        queryParameters: {'role': 'patient', 'first': 0, 'max': 100},
      );

      final patients = (response.data ?? const [])
          .whereType<Map>()
          .map(
            (value) => _PatientSummary.fromJson(
              value.map((key, item) => MapEntry(key.toString(), item)),
            ),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _patients = patients;
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      setState(() {
        _error = data is Map && data['detail'] is String
            ? data['detail'] as String
            : 'Unable to load patients from the identity service.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final patients = query.isEmpty
        ? _patients
        : _patients
            .where(
              (patient) =>
                  patient.name.toLowerCase().contains(query) ||
                  patient.email.toLowerCase().contains(query),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Patients')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadPatients)
              : RefreshIndicator(
                  onRefresh: _loadPatients,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search patients',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${patients.length} patient${patients.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 10),
                      if (patients.isEmpty)
                        const _EmptyPatients()
                      else
                        for (final patient in patients)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: .10),
                                child: Text(
                                  patient.initials,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(patient.name),
                              subtitle: Text(
                                [
                                  patient.email,
                                  if (patient.phone != null) patient.phone!,
                                ].join('\n'),
                              ),
                              isThreeLine: patient.phone != null,
                            ),
                          ),
                    ],
                  ),
                ),
    );
  }
}

class _PatientSummary {
  const _PatientSummary({
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

  factory _PatientSummary.fromJson(Map<String, dynamic> json) {
    final first = json['firstName']?.toString().trim() ?? '';
    final last = json['lastName']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    final attributes = _map(json['attributes']);
    final email = json['email']?.toString() ?? '';
    final fallbackName =
        json['username']?.toString().trim().isNotEmpty == true
            ? json['username'].toString()
            : email;

    return _PatientSummary(
      id: json['id']?.toString() ?? '',
      name: combined.isNotEmpty ? combined : fallbackName,
      email: email,
      phone: _firstValue(attributes['phone']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String? _firstValue(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first?.toString();
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _EmptyPatients extends StatelessWidget {
  const _EmptyPatients();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 52, color: AppTheme.primary),
          SizedBox(height: 14),
          Text('No patient accounts were returned.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
