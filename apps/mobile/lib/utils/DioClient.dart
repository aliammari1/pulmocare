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
          'Content-Type': 'application/json',
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
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              '[HTTP] ${error.response?.statusCode ?? 'ERR'} '
              '${error.requestOptions.method} '
              '${error.requestOptions.uri}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  static final DioHttpClient _instance = DioHttpClient._internal();

  factory DioHttpClient() => _instance;

  late final Dio dio;
}
