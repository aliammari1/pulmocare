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

enum NotificationType { todo, appointment }

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
