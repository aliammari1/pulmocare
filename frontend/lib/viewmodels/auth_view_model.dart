import 'package:flutter/material.dart';
import '../models/doctor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'dart:async';
import 'dart:io';

class AuthViewModel extends ChangeNotifier {
  Doctor? currentDoctor;
  bool isAuthenticated = false;
  String errorMessage = '';
  String? authToken;

  Future<void> login(String email, String password) async {
    try {
      print('Attempting login with: $email'); // Debug log

      final response = await http.post(
        Uri.parse(ApiConfig.login), // Use ApiConfig instead of hardcoded URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        authToken = data['token'];
        currentDoctor = Doctor(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          specialty: data['specialty'],
          phoneNumber: data['phone_number'],
          address: data['address'],
          profileImage: data['profile_image'],
          isVerified: data['is_verified'] ?? false,
          verificationDetails: data['verification_details'],
          signature: data['signature'],
        );
        isAuthenticated = true;
        errorMessage = '';
      } else {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Login failed';
        isAuthenticated = false;
      }
    } catch (e) {
      print('Login error: $e'); // Debug log
      errorMessage = 'Network error: ${e.toString()}';
      isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password,
      String specialty, String phoneNumber, String address) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiConfig.signup),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'specialty': specialty,
          'phoneNumber': phoneNumber,
          'address': address,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      if (response.statusCode == 201) {
        await login(email, password);
      } else {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Signup failed';
        isAuthenticated = false;
      }
    } on TimeoutException catch (_) {
      errorMessage = 'Connection timed out. Please try again.';
      isAuthenticated = false;
    } on SocketException catch (_) {
      errorMessage = 'Network error. Please check your internet connection.';
      isAuthenticated = false;
    } catch (e) {
      errorMessage = 'Network error: ${e.toString()}';
      isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    errorMessage = '';
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPassword), // Use ApiConfig
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Failed to send OTP';
      }
    } catch (e) {
      errorMessage =
          'Connection failed. Please check your internet connection.';
    }
    notifyListeners();
  }

  Future<bool> verifyOTP(String email, String otp) async {
    errorMessage = '';
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOTP), // Use ApiConfig
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Invalid OTP';
        return false;
      }
    } catch (e) {
      errorMessage =
          'Connection failed. Please check your internet connection.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> resetPassword(
      String email, String otp, String newPassword) async {
    errorMessage = '';
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword), // Use ApiConfig
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Failed to reset password';
        return false;
      }
    } catch (e) {
      errorMessage =
          'Connection failed. Please check your internet connection.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    if (authToken == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentDoctor = Doctor(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          specialty: data['specialty'],
          phoneNumber: data['phone_number'],
          address: data['address'],
          profileImage: data['profile_image'],
          isVerified: data['is_verified'] ?? false,
          verificationDetails: data['verification_details'],
          signature: data['signature'], // Add this line
        );
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to fetch profile';
      notifyListeners();
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.changePassword),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Failed to change password';
      } else {
        errorMessage = '';
      }
    } catch (e) {
      errorMessage = 'Network error: ${e.toString()}';
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String specialty,
    required String phoneNumber,
    required String address,
    String? base64Image,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateProfile),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'specialty': specialty,
          'phone_number': phoneNumber,
          'address': address,
          'profile_image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentDoctor = Doctor(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          specialty: data['specialty'],
          phoneNumber: data['phone_number'],
          address: data['address'],
          profileImage: base64Image ?? currentDoctor?.profileImage,
          isVerified: data['is_verified'] ??
              currentDoctor?.isVerified ??
              false, // Preserve verification status
          verificationDetails: data['verification_details'] ??
              currentDoctor?.verificationDetails,
        );
        errorMessage = '';
      } else {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Failed to update profile';
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    if (authToken == null) return;
    try {
      await http.post(
        Uri.parse(ApiConfig.logout),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      authToken = null;
      currentDoctor = null;
      errorMessage = '';
      isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Network error: $e';
      notifyListeners();
    }
  }

  Future<bool> verifyDoctor(String base64Image, String language) async {
    try {
      clearError();

      final response = await http.post(
        Uri.parse(ApiConfig.verifyDoctor),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'image': base64Image, 'language': language}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('verified') && data['verified'] == true) {
          if (currentDoctor != null) {
            currentDoctor = Doctor(
              id: currentDoctor!.id,
              name: currentDoctor!.name,
              email: currentDoctor!.email,
              specialty: currentDoctor!.specialty,
              phoneNumber: currentDoctor!.phoneNumber,
              address: currentDoctor!.address,
              profileImage: currentDoctor!.profileImage,
              isVerified: true,
              verificationDetails: data['verification_details'],
              signature: currentDoctor!.signature,
            );
          }
          notifyListeners();
          return true;
        }

        setErrorMessage(data['error'] ?? 'Verification failed');
        return false;
      } else {
        final data = json.decode(response.body);
        setErrorMessage(data['error'] ?? 'Verification failed');
        return false;
      }
    } catch (e) {
      setErrorMessage('Verification error: $e');
      return false;
    }
  }

  void clearError() {
    errorMessage = '';
    notifyListeners();
  }

  void setErrorMessage(String message) {
    errorMessage = message;
    notifyListeners();
  }

  Future<void> updateSignature(String signatureBase64) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateSignature),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'signature': signatureBase64,
        }),
      );

      if (response.statusCode == 200) {
        if (currentDoctor != null) {
          currentDoctor = Doctor(
            id: currentDoctor!.id,
            name: currentDoctor!.name,
            email: currentDoctor!.email,
            specialty: currentDoctor!.specialty,
            phoneNumber: currentDoctor!.phoneNumber,
            address: currentDoctor!.address,
            profileImage: currentDoctor!.profileImage,
            isVerified: currentDoctor!.isVerified,
            verificationDetails: currentDoctor!.verificationDetails,
            signature: signatureBase64,
          );
        }
        errorMessage = '';
      } else {
        final data = json.decode(response.body);
        errorMessage = data['error'] ?? 'Failed to update signature';
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
    }
    notifyListeners();
  }
}
