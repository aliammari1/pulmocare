import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';
import 'viewmodels/ordonnance_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedApp());
}

class MedApp extends StatelessWidget {
  const MedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrdonnanceViewModel()),
      ],
      child: MaterialApp(
        title: 'Medical App',
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.home,
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
