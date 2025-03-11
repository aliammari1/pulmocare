import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:logging/logging.dart';

class FaceAuthService {
  final _logger = Logger('FaceAuthService');
  final String baseUrl = 'http://localhost:5000/api';

  Future<bool> verifyFace(String email, XFile imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/patient/verify-face');
      final request = http.MultipartRequest('POST', uri)
        ..fields['email'] = email
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final result = jsonDecode(responseData);

      return result['match'] ?? false;
    } catch (e) {
      _logger.warning('Face verification error: $e');
      return false;
    }
  }

  Future<String?> registerFace(String email, XFile imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/patient/register-face');
      final request = http.MultipartRequest('POST', uri)
        ..fields['email'] = email
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final result = jsonDecode(responseData);

      return result['message'];
    } catch (e) {
      _logger.warning('Face registration error: $e');
      return null;
    }
  }
}
