import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.medical_services, size: 30),
                ),
                SizedBox(height: 10),
                Text(
                  'Medical App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Nouvelle Ordonnance'),
            onTap: () => Navigator.pushNamed(context, AppRouter.newOrdonnance),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Mes Ordonnances'),
            onTap: () =>
                Navigator.pushNamed(context, AppRouter.ordonnancesList),
          ),
        ],
      ),
    );
  }
}
