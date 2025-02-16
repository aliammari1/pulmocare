import 'package:flutter/material.dart';
import 'package:medicare/theme/app_theme.dart';
import 'package:medicare/views/profile_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
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
        automaticallyImplyLeading: false, // Add this line to remove back arrow
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppTheme.turquoise,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.turquoise),
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
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppTheme.turquoise,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            iconSize: 24,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Patients',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Function() {
  read() {}
}
