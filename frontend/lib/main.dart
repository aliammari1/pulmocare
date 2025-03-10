import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/entry_view.dart'; // Add this import
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: MaterialApp(
        title: 'Medicare',
        theme: AppTheme.lightTheme,
        home: const EntryView(),
        routes: {
          // Remove '/login' route since we're handling it through EntryView
          '/home': (context) => const HomeView(),
        },
      ),
    );
  }
}
