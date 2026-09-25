import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/AppointmentsScreen.dart';
import 'screens/entry_view.dart';
import 'screens/home_view.dart';
import 'screens/login_view.dart';
import 'screens/patients_view.dart';
import 'screens/reports/reports_list_screen.dart';
import 'services/auth_view_model.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TokenStorage.instance.initialize();
  final authViewModel = AuthViewModel();
  await authViewModel.restoreSession();

  FlutterError.onError = FlutterError.presentError;

  runApp(
    ChangeNotifierProvider.value(
      value: authViewModel,
      child: const MedicalApp(),
    ),
  );
}

class MedicalApp extends StatelessWidget {
  const MedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulmoCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AuthViewModel>(
        builder: (context, auth, _) =>
            auth.isAuthenticated ? const HomeView() : const EntryView(),
      ),
      routes: {
        '/home': (_) => const HomeView(),
        '/login': (_) => const LoginView(userType: 'doctor'),
        '/loginRadio': (_) => const LoginView(userType: 'radiologist'),
        '/loginScreen': (_) => const LoginView(userType: 'patient'),
        '/reportsList': (_) => const ReportsListScreen(),
        '/appointmentsScreen': (_) => const AppointmentsScreen(),
        '/patients_doctor': (_) => const PatientsView(),
      },
    );
  }
}
