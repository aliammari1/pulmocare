class ApiConfig {
  // Use your local IP address and port
  static const String baseUrl =
      'http://192.168.1.194:4000/api'; // Added /api to match backend

  // API endpoints
  static const String login = '$baseUrl/login'; // Removed /auth prefix
  static const String signup = '$baseUrl/signup'; // Removed /auth prefix
  static const String profile = '$baseUrl/profile';
  static const String updateProfile = '$baseUrl/update-profile';
  static const String changePassword = '$baseUrl/change-password';
  static const String forgotPassword = '$baseUrl/forgot-password';
  static const String resetPassword = '$baseUrl/reset-password';
  static const String logout = '$baseUrl/logout';
}
