import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:medapp/models/doctor.dart';
import 'package:medapp/services/token_storage.dart';
import 'package:medapp/utils/DioClient.dart';

class AuthViewModel extends ChangeNotifier {
  final Dio _dio = DioHttpClient().dio;
  final TokenStorage _tokens = TokenStorage.instance;

  Doctor? currentDoctor;
  bool isAuthenticated = false;
  bool isBusy = false;
  String errorMessage = '';
  String? userRole;
  String? userId;
  String? userEmail;
  String? displayName;

  String? get authToken => _tokens.accessToken;

  Future<void> restoreSession() async {
    final refreshToken = _tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/token/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = response.data ?? const {};
      final access = data['access_token']?.toString();
      final rotatedRefresh = data['refresh_token']?.toString();

      if (access == null || access.isEmpty) {
        throw const FormatException('Invalid refresh response');
      }

      await _tokens.saveSession(
        accessToken: access,
        refreshToken: rotatedRefresh == null || rotatedRefresh.isEmpty
            ? refreshToken
            : rotatedRefresh,
      );
      await _loadIdentity(access);
      isAuthenticated = true;
    } catch (_) {
      await _clearSession();
    }
    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password, {
    String? expectedRole,
  }) async {
    _setBusy(true);
    errorMessage = '';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/login',
        data: {'email': email.trim(), 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );

      final data = response.data ?? const {};
      final access = data['access_token']?.toString();
      final refresh = data['refresh_token']?.toString();

      if (access == null || refresh == null) {
        throw const FormatException('Authentication response is incomplete');
      }

      await _tokens.saveSession(accessToken: access, refreshToken: refresh);

      userId = data['user_id']?.toString();
      userEmail = data['email']?.toString() ?? email.trim();
      displayName = data['name']?.toString();
      userRole = data['role']?.toString();

      if (userRole == null || userRole!.isEmpty) {
        await _loadIdentity(access);
      }

      if (expectedRole != null &&
          userRole != null &&
          userRole!.isNotEmpty &&
          userRole != expectedRole) {
        await _clearSession();
        errorMessage =
            'This account is registered as ${_readableRole(userRole!)}. '
            'Choose the matching sign-in option.';
        return false;
      }

      _buildCompatibilityProfile(data);
      isAuthenticated = true;
      return true;
    } on DioException catch (error) {
      errorMessage = _messageFromDio(error, fallback: 'Unable to sign in.');
      await _clearSession();
      return false;
    } catch (_) {
      errorMessage = 'Unable to sign in. Please try again.';
      await _clearSession();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> signupPatient({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    _setBusy(true);
    errorMessage = '';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'username': email.trim(),
          'phone': phone?.trim(),
          'address': address?.trim(),
          'role': 'patient',
        },
        options: Options(extra: {'skipAuth': true}),
      );

      final data = response.data ?? const {};
      final access = data['access_token']?.toString();
      final refresh = data['refresh_token']?.toString();

      if (access != null && refresh != null) {
        await _tokens.saveSession(accessToken: access, refreshToken: refresh);
        await _loadIdentity(access);
        isAuthenticated = true;
        return true;
      }

      return await login(email, password, expectedRole: 'patient');
    } on DioException catch (error) {
      errorMessage =
          _messageFromDio(error, fallback: 'Unable to create the account.');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setBusy(true);
    errorMessage = '';

    try {
      await _dio.post<Map<String, dynamic>>(
        'auth/forgot-password',
        data: {'email': email.trim()},
        options: Options(extra: {'skipAuth': true}),
      );
      return true;
    } on DioException catch (error) {
      errorMessage = _messageFromDio(
        error,
        fallback: 'Unable to request a password reset.',
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> fetchProfile() async {
    if (!isAuthenticated) return;

    try {
      final response =
          await _dio.get<Map<String, dynamic>>('auth/profile');
      final data = response.data ?? const {};
      final attributes = _asMap(data['attributes']);

      userId = data['id']?.toString() ?? userId;
      userEmail = data['email']?.toString() ?? userEmail;
      displayName = _profileName(data);
      userRole = data['role']?.toString() ?? userRole;

      currentDoctor = Doctor(
        id: userId ?? '',
        name: displayName ?? userEmail ?? 'PulmoCare user',
        email: userEmail ?? '',
        specialty: attributes['specialty']?.toString() ?? '',
        phoneNumber: attributes['phone']?.toString() ?? '',
        address: attributes['address']?.toString() ?? '',
        profileImage: attributes['profile_image']?.toString(),
        isVerified: _asBool(attributes['is_verified']),
        verificationDetails:
            attributes['verification_details'] is Map<String, dynamic>
                ? attributes['verification_details'] as Map<String, dynamic>
                : null,
        signature: attributes['signature']?.toString(),
      );
      notifyListeners();
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _clearSession();
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    final refresh = _tokens.refreshToken;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _dio.post<Map<String, dynamic>>(
          'auth/logout',
          data: {'refresh_token': refresh},
        );
      }
    } catch (_) {
      // Local logout must still succeed when the network is unavailable.
    } finally {
      await _clearSession();
      notifyListeners();
    }
  }

  Future<void> _loadIdentity(String accessToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/token/verify',
      data: {'token': accessToken},
      options: Options(extra: {'skipAuth': true}),
    );
    final data = response.data ?? const {};
    if (data['valid'] != true) {
      throw const FormatException('Invalid access token');
    }

    userId = data['user_id']?.toString();
    userEmail = data['email']?.toString();
    displayName = data['name']?.toString() ?? userEmail;
    userRole = data['primary_role']?.toString();

    currentDoctor = Doctor(
      id: userId ?? '',
      name: displayName ?? 'PulmoCare user',
      email: userEmail ?? '',
      specialty: '',
      phoneNumber: '',
      address: '',
    );
  }

  void _buildCompatibilityProfile(Map<String, dynamic> data) {
    currentDoctor = Doctor(
      id: userId ?? '',
      name: displayName ?? userEmail ?? 'PulmoCare user',
      email: userEmail ?? '',
      specialty: '',
      phoneNumber: '',
      address: '',
    );
  }

  Future<void> _clearSession() async {
    await _tokens.clear();
    isAuthenticated = false;
    userRole = null;
    userId = null;
    userEmail = null;
    displayName = null;
    currentDoctor = null;
  }

  void _setBusy(bool value) {
    isBusy = value;
    notifyListeners();
  }

  static String _readableRole(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static String? _profileName(Map<String, dynamic> data) {
    final first = data['firstName']?.toString().trim() ?? '';
    final last = data['lastName']?.toString().trim() ?? '';
    final full = '$first $last'.trim();
    return full.isNotEmpty
        ? full
        : data['username']?.toString() ?? data['email']?.toString();
  }

  static String _messageFromDio(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'] ?? data['error'] ?? data['message'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the PulmoCare server. Check your connection.';
    }
    return fallback;
  }
}
