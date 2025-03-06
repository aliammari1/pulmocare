// Non-web platform implementation
// This file is imported on non-web platforms
// Contains platform-specific code for speech recognition

class WebSpeechSupport {
  static Future<bool> checkMicrophonePermission() async {
    // On mobile platforms, this would use platform-specific permission checks
    return true;
  }

  static Future<bool> requestMicrophonePermission() async {
    // On mobile platforms, this would use platform-specific permission requests
    return true;
  }

  static String getPlatformName() {
    // Would return the actual platform name in a real implementation
    return 'Mobile/Desktop';
  }
}
