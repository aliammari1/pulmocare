import 'package:dio/dio.dart';

import '../models/clinical_provider.dart';
import '../utils/dio_client.dart';

class ProviderDirectoryService {
  ProviderDirectoryService({Dio? dio}) : _dio = dio ?? DioHttpClient().dio;

  final Dio _dio;

  Future<List<ClinicalProvider>> listProviders() async {
    final response = await _dio.get<List<dynamic>>(
      'auth/providers',
      queryParameters: const {'first': 0, 'max': 100},
    );

    return (response.data ?? const [])
        .whereType<Map>()
        .map(
          (item) => ClinicalProvider.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((provider) => provider.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
