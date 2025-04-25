import 'package:flutter/material.dart';
import 'package:medicare/widgets/notification_popup.dart';
import 'package:medicare/services/notification_service.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class PatientView extends StatefulWidget {
  const PatientView({Key? key}) : super(key: key);

  @override
  State<PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends State<PatientView> {
  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('patients')),
      ),
      body: Column(
        children: [
          // Prominent notification button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.turquoise,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const NotificationPopup(),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('check_notifications'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (notificationService.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notificationService.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Patient list
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Replace with actual patient count
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.turquoise,
                      child: Text('P${index + 1}'),
                    ),
                    title: Text('Patient ${index + 1}'),
                    subtitle: Text('Next appointment: ${_getRandomTime()}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to patient detail
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.turquoise,
        child: const Icon(Icons.add),
        onPressed: () {
          // Add new patient logic
        },
      ),
    );
  }

  String _getRandomTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day + (now.minute % 10)).toString().padLeft(2, '0')} ${(now.hour % 12 + 1).toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }
}
