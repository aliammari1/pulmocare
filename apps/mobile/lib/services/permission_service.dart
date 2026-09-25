import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCameraPermission() async =>
      (await Permission.camera.request()).isGranted;

  Future<bool> requestMicrophonePermission() async =>
      (await Permission.microphone.request()).isGranted;

  Future<bool> requestNotificationPermission() async =>
      (await Permission.notification.request()).isGranted;

  Future<Map<Permission, bool>> checkPermissions() async {
    return {
      Permission.camera: await Permission.camera.isGranted,
      Permission.microphone: await Permission.microphone.isGranted,
      Permission.notification: await Permission.notification.isGranted,
    };
  }

  Future<bool> shouldShowRationale(Permission permission) =>
      permission.shouldShowRequestRationale;

  Future<bool> openSystemSettings() => openAppSettings();
}
