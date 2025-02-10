import 'package:flutter/material.dart';
import 'package:medicare/theme/app_theme.dart';
import 'package:medicare/views/profile_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'profile_view.dart' as profile_view;
import 'patients_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ProfileView(),
    PatientsView(),
  ];

  final List<String> _titles = ['Profile', 'Patients'];

  @override
  void initState() {
    super.initState();
    // Fetch profile data when home view is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    TextButton(
                      child: const Text('Yes, Logout'),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                await context.read<AuthViewModel>().logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.kPrimaryBlue,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              label: 'Profile',
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
            ),
            BottomNavigationBarItem(
              label: 'Patients',
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Function() {
  read() {}
}
