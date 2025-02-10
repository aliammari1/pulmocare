import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: MaterialApp(
        title: 'Medicare',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginView(),
          '/home': (context) => const HomeView(),
        },
        home: Consumer<AuthViewModel>(
          builder: (context, authVM, child) {
            return authVM.isAuthenticated ? HomeView() : LoginView();
          },
        ),
      ),
    );
  }
}
