import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicare/services/notification_service.dart';
import 'package:provider/provider.dart';

class NotificationPopup extends StatefulWidget {
  const NotificationPopup({Key? key}) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedTabIndex = 0;

  // Add a map to store attendance statuses with appointment IDs as keys
  Map<String, String> attendanceStatuses = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final notifications = notificationService.notifications;
    final todaysAppointments = _getTodaysAppointments(notificationService);

    return ScaleTransition(
      scale: _animation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with tabs
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 8, top: 8, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Schedule",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              _controller.reverse().then((value) {
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Tab bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          _buildTab(0, "Appointments"),
                          _buildTab(1, "Notifications"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content based on selected tab
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildAppointmentsTab(todaysAppointments)
                    : _buildNotificationsTab(
                        notifications, notificationService),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_selectedTabIndex == 1 && notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          notificationService.markAllAsRead();
                        },
                        child: const Text('Mark All as Read'),
                      ),
                    TextButton(
                      onPressed: () {
                        _controller.reverse().then((value) {
                          Navigator.of(context).pop();
                        });
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab widget builder
  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // Today's appointments tab
  Widget _buildAppointmentsTab(List<Map<String, dynamic>> appointments) {
    if (appointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No appointments scheduled for today',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: appointments.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final timeFormat = DateFormat('h:mm a');
        final startTime = appointment['startTime'] as DateTime;
        final endTime = appointment['endTime'] as DateTime;
        final now = DateTime.now();

        // Generate a unique key for this appointment
        final String appointmentId =
            '${appointment['patientName']}_${startTime.millisecondsSinceEpoch}';

        // Check if appointment is current (happening now)
        final bool isCurrent = startTime.isBefore(now) && endTime.isAfter(now);
        // Check if appointment is past
        final bool isPast = endTime.isBefore(now);

        // Get attendance status from our state map or default to 'unknown'
        final String attendanceStatus =
            attendanceStatuses[appointmentId] ?? 'unknown';

        // Determine background color based on attendance status
        Color? backgroundColor;
        if (attendanceStatus == 'present') {
          backgroundColor = Colors.green.shade100;
        } else if (attendanceStatus == 'absent') {
          backgroundColor = Colors.red.shade100;
        }

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrent
                  ? Colors.red.shade100
                  : appointment['isUpcoming']
                      ? Colors.amber.shade100
                      : Colors.blue.shade100,
              foregroundColor: isCurrent
                  ? Colors.red.shade800
                  : appointment['isUpcoming']
                      ? Colors.amber.shade800
                      : Colors.blue.shade800,
              child: Text(appointment['patientName'].substring(0, 1)),
            ),
            title: Text(
              appointment['patientName'],
              style: TextStyle(
                fontWeight: (appointment['isUpcoming'] || isCurrent)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}'),
                Text('Reason: ${appointment['reason']}'),
                if (isPast && attendanceStatus != 'unknown')
                  Text(
                    'Status: ${attendanceStatus == 'present' ? 'Patient attended' : 'Patient absent'}',
                    style: TextStyle(
                      color: attendanceStatus == 'present'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: isCurrent
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text(
                              'BUSY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : appointment['isUpcoming']
                    ? const Icon(Icons.access_time, color: Colors.amber)
                    : isPast && attendanceStatus == 'unknown'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.grey,
                                ),
                                tooltip: 'Mark as present',
                                onPressed: () {
                                  setState(() {
                                    // Update our state map instead of the appointment map
                                    attendanceStatuses[appointmentId] =
                                        'present';
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.grey,
                                ),
                                tooltip: 'Mark as absent',
                                onPressed: () {
                                  setState(() {
                                    // Update our state map instead of the appointment map
                                    attendanceStatuses[appointmentId] =
                                        'absent';
                                  });
                                },
                              ),
                            ],
                          )
                        : null,
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // Notifications tab
  Widget _buildNotificationsTab(
      List<NotificationItem> notifications, NotificationService service) {
    if (notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No notifications',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(context, notification, service);
      },
    );
  }

  // Get today's appointments
  List<Map<String, dynamic>> _getTodaysAppointments(
      NotificationService notificationService) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Generate some example appointments for demonstration
    // In a real app, this would come from a database or API
    List<Map<String, dynamic>> appointments = [
      {
        'patientName': 'John Smith',
        'startTime': today.add(const Duration(hours: 9, minutes: 0)),
        'endTime': today.add(const Duration(hours: 9, minutes: 30)),
        'reason': 'Annual checkup',
        'isUpcoming':
            today.add(const Duration(hours: 9, minutes: 0)).isAfter(now),
      },
      {
        'patientName': 'Emily Johnson',
        'startTime': today.add(const Duration(hours: 10, minutes: 0)),
        'endTime': today.add(const Duration(hours: 10, minutes: 45)),
        'reason': 'Follow-up consultation',
        'isUpcoming':
            today.add(const Duration(hours: 10, minutes: 0)).isAfter(now),
      },
      {
        'patientName': 'Robert Davis',
        'startTime': today.add(const Duration(hours: 11, minutes: 30)),
        'endTime': today.add(const Duration(hours: 12, minutes: 0)),
        'reason': 'Medication review',
        'isUpcoming':
            today.add(const Duration(hours: 11, minutes: 30)).isAfter(now),
      },
      {
        'patientName': 'Sarah Wilson',
        'startTime': today.add(const Duration(hours: 13, minutes: 0)),
        'endTime': today.add(const Duration(hours: 13, minutes: 30)),
        'reason': 'Blood pressure check',
        'isUpcoming':
            today.add(const Duration(hours: 13, minutes: 0)).isAfter(now),
      },
      {
        'patientName': 'Michael Brown',
        'startTime': today.add(const Duration(hours: 14, minutes: 15)),
        'endTime': today.add(const Duration(hours: 15, minutes: 0)),
        'reason': 'Specialist consultation',
        'isUpcoming':
            today.add(const Duration(hours: 14, minutes: 15)).isAfter(now),
      },
      {
        'patientName': 'Jennifer Lee',
        'startTime': today.add(const Duration(hours: 15, minutes: 30)),
        'endTime': today.add(const Duration(hours: 17, minutes: 0)),
        'reason': 'Lab results discussion',
        'isUpcoming':
            today.add(const Duration(hours: 15, minutes: 30)).isAfter(now),
      },
    ];

    // Sort appointments by time
    appointments.sort((a, b) => a['startTime'].compareTo(b['startTime']));

    // Also include any appointments from notifications
    for (var notification in notificationService.notifications) {
      if (notification.type == NotificationType.appointment) {
        final appt = notification as AppointmentNotification;
        final apptDate = DateTime(
          appt.appointmentTime.year,
          appt.appointmentTime.month,
          appt.appointmentTime.day,
        );

        // If appointment is today and not already in the list
        if (apptDate == today) {
          bool alreadyExists = appointments.any((existing) =>
              existing['patientName'] == appt.patientName &&
              existing['startTime'] == appt.appointmentTime);

          if (!alreadyExists) {
            appointments.add({
              'patientName': appt.patientName,
              'startTime': appt.appointmentTime,
              'endTime': appt.appointmentTime.add(const Duration(minutes: 30)),
              'reason': appt.patientInfo,
              'isUpcoming': appt.appointmentTime.isAfter(now),
            });
          }
        }
      }
    }

    return appointments;
  }

  // Build notification item
  Widget _buildNotificationItem(BuildContext context,
      NotificationItem notification, NotificationService service) {
    final dateFormatter = DateFormat('hh:mm a');

    if (notification.type == NotificationType.appointment) {
      final appointment = notification as AppointmentNotification;
      return Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.calendar_today, color: Colors.blue),
          ),
          title: Text(
            'Appointment with ${appointment.patientName}',
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Time: ${dateFormatter.format(appointment.appointmentTime)}'),
              Text('Info: ${appointment.patientInfo}'),
            ],
          ),
          trailing: notification.isRead
              ? null
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => service.markAsRead(notification.id),
                ),
        ),
      );
    } else {
      final todo = notification as TodoNotification;
      return Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: const Icon(Icons.check_circle_outline, color: Colors.green),
          ),
          title: Text(
            todo.task,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text('Due: ${dateFormatter.format(todo.dueTime)}'),
          trailing: notification.isRead
              ? null
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => service.markAsRead(notification.id),
                ),
        ),
      );
    }
  }
}
