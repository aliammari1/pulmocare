import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notification type enum
enum NotificationType { todo, appointment }

// Base notification item class
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime dateTime;
  final Map<String, dynamic>? data;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.dateTime,
    this.data,
    this.isRead = false,
  });
}

// Appointment notification class
class AppointmentNotification extends NotificationItem {
  final String patientName;
  final DateTime appointmentTime;
  final String patientInfo;

  AppointmentNotification({
    required String id,
    required String title,
    required String body,
    required this.patientName,
    required this.appointmentTime,
    required this.patientInfo,
    bool isRead = false,
  }) : super(
          id: id,
          title: title,
          body: body,
          type: NotificationType.appointment,
          dateTime: DateTime.now(),
          data: {
            'patientName': patientName,
            'appointmentTime': appointmentTime.toIso8601String(),
            'patientInfo': patientInfo,
          },
          isRead: isRead,
        );
}

// Todo notification class
class TodoNotification extends NotificationItem {
  final String task;
  final DateTime dueTime;

  TodoNotification({
    required String id,
    required String title,
    required String body,
    required this.task,
    required this.dueTime,
    bool isRead = false,
  }) : super(
          id: id,
          title: title,
          body: body,
          type: NotificationType.todo,
          dateTime: DateTime.now(),
          data: {
            'task': task,
            'dueTime': dueTime.toIso8601String(),
          },
          isRead: isRead,
        );
}

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  NotificationService() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString('notifications');

    if (notificationsJson != null) {
      final List<dynamic> decodedList = jsonDecode(notificationsJson);
      for (var item in decodedList) {
        if (item['type'] == 'appointment') {
          _notifications.add(
            AppointmentNotification(
              id: item['id'],
              title: item['title'],
              body: item['body'],
              patientName: item['data']['patientName'],
              appointmentTime: DateTime.parse(item['data']['appointmentTime']),
              patientInfo: item['data']['patientInfo'],
              isRead: item['isRead'],
            ),
          );
        } else if (item['type'] == 'todo') {
          _notifications.add(
            TodoNotification(
              id: item['id'],
              title: item['title'],
              body: item['body'],
              task: item['data']['task'],
              dueTime: DateTime.parse(item['data']['dueTime']),
              isRead: item['isRead'],
            ),
          );
        }

        if (!item['isRead']) {
          _unreadCount++;
        }
      }
      notifyListeners();
    }
  }

  // Method to add sample notifications for demo purposes
  Future<void> addSampleNotifications() async {
    final now = DateTime.now();

    // Add a sample appointment notification
    addAppointmentNotification(
      patientName: 'John Doe',
      appointmentTime: now.add(const Duration(hours: 2)),
      patientInfo: 'Follow-up checkup',
    );

    // Add a sample todo notification
    addTodoNotification(
      task: 'Review patient files',
      dueTime: now.add(const Duration(hours: 4)),
    );

    notifyListeners();
  }

  Future<void> addAppointmentNotification({
    required String patientName,
    required DateTime appointmentTime,
    required String patientInfo,
  }) async {
    final notification = AppointmentNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Appointment Reminder',
      body:
          'You have an appointment with $patientName at ${_formatTime(appointmentTime)}',
      patientName: patientName,
      appointmentTime: appointmentTime,
      patientInfo: patientInfo,
    );

    _notifications.add(notification);
    _unreadCount++;
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> addTodoNotification({
    required String task,
    required DateTime dueTime,
  }) async {
    final notification = TodoNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Todo Reminder',
      body: 'Task: $task due at ${_formatTime(dueTime)}',
      task: task,
      dueTime: dueTime,
    );

    _notifications.add(notification);
    _unreadCount++;
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      if (!notification.isRead) {
        _unreadCount--;
      }

      if (notification.type == NotificationType.appointment) {
        _notifications[index] = AppointmentNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          patientName: (notification as AppointmentNotification).patientName,
          appointmentTime: (notification).appointmentTime,
          patientInfo: (notification).patientInfo,
          isRead: true,
        );
      } else if (notification.type == NotificationType.todo) {
        _notifications[index] = TodoNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          task: (notification as TodoNotification).task,
          dueTime: (notification).dueTime,
          isRead: true,
        );
      }

      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      final notification = _notifications[i];
      if (!notification.isRead) {
        if (notification.type == NotificationType.appointment) {
          _notifications[i] = AppointmentNotification(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            patientName: (notification as AppointmentNotification).patientName,
            appointmentTime: (notification).appointmentTime,
            patientInfo: (notification).patientInfo,
            isRead: true,
          );
        } else if (notification.type == NotificationType.todo) {
          _notifications[i] = TodoNotification(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            task: (notification as TodoNotification).task,
            dueTime: (notification).dueTime,
            isRead: true,
          );
        }
      }
    }

    _unreadCount = 0;
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> notificationsToSave = [];

    for (var notification in _notifications) {
      final Map<String, dynamic> notificationMap = {
        'id': notification.id,
        'title': notification.title,
        'body': notification.body,
        'type': notification.type == NotificationType.appointment
            ? 'appointment'
            : 'todo',
        'dateTime': notification.dateTime.toIso8601String(),
        'data': notification.data,
        'isRead': notification.isRead,
      };

      notificationsToSave.add(notificationMap);
    }

    await prefs.setString('notifications', jsonEncode(notificationsToSave));
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
