import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:medapp/config.dart';
import 'package:medapp/services/token_storage.dart';

class DioHttpClient {
  DioHttpClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.extra['skipAuth'] != true) {
            final token = TokenStorage.instance.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          options.headers['X-Request-ID'] =
              DateTime.now().microsecondsSinceEpoch.toString();

          if (kDebugMode) {
            debugPrint('[HTTP] ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[HTTP] ${response.statusCode} '
              '${response.requestOptions.method} '
              '${response.requestOptions.uri}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              '[HTTP] ${error.response?.statusCode ?? 'ERR'} '
              '${error.requestOptions.method} '
              '${error.requestOptions.uri}',
            );
          }

          if (!_canRefresh(error)) {
            handler.next(error);
            return;
          }

          try {
            final accessToken = await _refreshAccessToken();
            if (accessToken == null) {
              handler.next(error);
              return;
            }

            final request = error.requestOptions;
            request.extra['retriedAfterRefresh'] = true;
            request.headers['Authorization'] = 'Bearer $accessToken';

            final response = await dio.fetch<dynamic>(request);
            handler.resolve(response);
          } catch (_) {
            await TokenStorage.instance.clear();
            handler.next(error);
          }
        },
      ),
    );
  }

  static final DioHttpClient _instance = DioHttpClient._internal();

  factory DioHttpClient() => _instance;

  late final Dio dio;
  Future<String?>? _refreshFuture;

  bool _canRefresh(DioException error) {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401) return false;
    if (request.extra['skipAuth'] == true) return false;
    if (request.extra['retriedAfterRefresh'] == true) return false;
    if (request.path.contains('auth/token/refresh')) return false;

    final refreshToken = TokenStorage.instance.refreshToken;
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<String?> _refreshAccessToken() {
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;

    final future = _performRefresh();
    _refreshFuture = future;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = TokenStorage.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final refreshClient = Dio(
      BaseOptions(
        baseUrl: Config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    final response = await refreshClient.post<Map<String, dynamic>>(
      'auth/token/refresh',
      data: {'refresh_token': refreshToken},
    );

    final data = response.data ?? const <String, dynamic>{};
    final access = data['access_token']?.toString();
    final rotatedRefresh = data['refresh_token']?.toString();

    if (access == null || access.isEmpty) return null;

    await TokenStorage.instance.saveSession(
      accessToken: access,
      refreshToken: rotatedRefresh == null || rotatedRefresh.isEmpty
          ? refreshToken
          : rotatedRefresh,
    );
    return access;
  }
}
