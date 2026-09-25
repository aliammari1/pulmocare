import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  static const _accessKey = 'pulmocare_access_token';
  static const _refreshKey = 'pulmocare_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> initialize() async {
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
