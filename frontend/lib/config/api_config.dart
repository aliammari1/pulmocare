class ApiConfig {
  // For running on physical devices, use your computer's actual IP address on your local network
  // Replace 192.168.1.X with your computer's actual IP address
static const String baseUrl = 'http://192.168.91.194:4000/api';

  // Alternative configurations (comment/uncomment as needed):
  //static const String baseUrl = 'http://10.0.2.2:4000/api';  // For Android emulator
  // static const String baseUrl = 'http://localhost:4000/api';  // For iOS simulator

  static const String login = '$baseUrl/login';
  static const String signup = '$baseUrl/signup';
  static const String forgotPassword = '$baseUrl/forgot-password';
  static const String verifyOTP = '$baseUrl/verify-otp';
  static const String resetPassword = '$baseUrl/reset-password';
  static const String profile = '$baseUrl/profile';
  static const String changePassword = '$baseUrl/change-password';
  static const String updateProfile = '$baseUrl/update-profile';
  static const String logout = '$baseUrl/logout';
  static const String verifyDoctor = '$baseUrl/verify-doctor';
  static const String updateSignature = '$baseUrl/update-signature';
}
