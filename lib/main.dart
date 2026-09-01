import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/theme/app_theme.dart';
import 'package:mtc2026/ui/screens/home_screen.dart';
import 'package:mtc2026/ui/screens/company_login_screen.dart';

// Conditional import to handle Desktop vs Web safely
import 'package:mtc2026/platform_init_desktop.dart' 
    if (dart.library.html) 'package:mtc2026/platform_init_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This call will execute Desktop initialization on Windows/Linux
  // and do nothing on Web, ensuring no crashes.
  initializePlatform();

  await initializeDateFormatting('el', null);
  Intl.defaultLocale = 'el';

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectProvider()..fetchProjects()),
      ],
      child: MyApp(startScreen: isLoggedIn ? const HomeScreen() : const CompanyLoginScreen()),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        return MaterialApp(
          title: 'MTC 2026',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: projectProvider.settings.appTheme == 'DARK'
              ? ThemeMode.dark
              : projectProvider.settings.appTheme == 'LIGHT'
                  ? ThemeMode.light
                  : ThemeMode.system,
          home: startScreen,
        );
      },
    );
  }
}
