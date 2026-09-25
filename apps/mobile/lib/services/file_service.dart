import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/DioClient.dart';

class UploadedFile {
  const UploadedFile({
    required this.bucket,
    required this.objectName,
    required this.filename,
    required this.contentType,
    required this.size,
  });

  final String bucket;
  final String objectName;
  final String filename;
  final String contentType;
  final int size;

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      bucket: (json['bucket'] ?? '').toString(),
      objectName: (json['object_name'] ?? '').toString(),
      filename: (json['filename'] ?? '').toString(),
      contentType: (json['content_type'] ?? 'application/octet-stream').toString(),
      size: json['size'] is int
          ? json['size'] as int
          : int.tryParse(json['size']?.toString() ?? '') ?? 0,
    );
  }
}

class FileService {
  FileService({Dio? dio}) : _dio = dio ?? DioHttpClient().dio;

  final Dio _dio;

  Future<UploadedFile> uploadVerificationDocument({
    required String filePath,
    required String filename,
    required String userId,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
      'bucket': 'patientdocuments',
      'folder': 'verification/$userId',
      'metadata': jsonEncode({
        'purpose': 'provider_verification',
      }),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      'files/upload',
      data: form,
    );

    final data = response.data ?? const <String, dynamic>{};
    final uploaded = UploadedFile.fromJson(data);
    if (uploaded.objectName.isEmpty || uploaded.bucket.isEmpty) {
      throw const FormatException('File service returned an incomplete upload response');
    }
    return uploaded;
  }
}
