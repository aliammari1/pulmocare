import 'package:flutter/material.dart';
import 'package:medicare/widgets/notification_icon.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localizations.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/news_viewmodel.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/entry_view.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:medicare/services/notification_service.dart';
import 'package:medicare/widgets/notification_popup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => NewsViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'Pulmocare',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('fr', ''), // French
        Locale('ar', ''), // Arabic
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Builder(builder: (context) {
          return Directionality(
            textDirection:
                languageProvider.isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          );
        });
      },
      home: const EntryView(),
      routes: {
        '/home': (context) => const HomeView(),
        '/entry': (context) => const EntryView(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    // Show notifications popup after 3 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          final notificationService =
              Provider.of<NotificationService>(context, listen: false);
          // Add sample notifications for demonstration
          notificationService.addSampleNotifications().then((_) {
            // Show the notification popup if notifications are available
            if (notificationService.notifications.isNotEmpty) {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => const NotificationPopup(),
              );
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulmocare'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          // Add notification icon before other actions
          const NotificationIcon(),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Pulmocare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Add more drawer items as needed
          ],
        ),
      ),
      body: Center(
        child: Text('Welcome to Pulmocare'),
      ),
    );
  }
}
