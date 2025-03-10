import 'api_service.dart';

abstract class BaseService {
  final ApiService _api;
  final String servicePath;
  
  BaseService(this._api, this.servicePath);

  Future<dynamic> getAll([Map<String, dynamic>? params]) async {
    return _api.get('api/$servicePath${_buildQueryString(params)}');
  }

  Future<dynamic> getById(String id) async {
    return _api.get('api/$servicePath/$id');
  }

  Future<dynamic> create(Map<String, dynamic> data) async {
    return _api.post('api/$servicePath', data);
  }

  Future<dynamic> update(String id, Map<String, dynamic> data) async {
    return _api.put('api/$servicePath/$id', data);
  }

  Future<dynamic> delete(String id) async {
    return _api.delete('api/$servicePath/$id');
  }

  String _buildQueryString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    return '?${Uri.encodeQueryComponent(
      params.entries.map((e) => '${e.key}=${e.value}').join('&')
    )}';
  }
}
