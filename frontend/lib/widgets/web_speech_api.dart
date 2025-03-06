// Web platform implementation
// This file is imported on web platforms
// Contains web-specific code for speech recognition

import 'dart:html' as html;

class WebSpeechSupport {
  static Future<bool> checkMicrophonePermission() async {
    try {
      final permission = await html.window.navigator.permissions
          ?.query({'name': 'microphone'});
      return permission?.state != 'denied';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    try {
      await html.window.navigator.getUserMedia(audio: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static String getBrowserName() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();

    if (userAgent.contains('edg')) return 'Edge';
    if (userAgent.contains('chrome')) return 'Chrome';
    if (userAgent.contains('firefox')) return 'Firefox';
    if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
      return 'Safari';
    }

    return 'Unknown';
  }
}
