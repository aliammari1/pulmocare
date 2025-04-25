import 'package:flutter/material.dart';
import 'package:medicare/services/notification_service.dart';
import 'package:medicare/widgets/notification_popup.dart';
import 'package:provider/provider.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final unreadCount = notificationService.unreadCount;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  size: 28, // Make icon bigger for visibility
                  color: Colors.amber, // Make it amber to stand out
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const NotificationPopup(),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
