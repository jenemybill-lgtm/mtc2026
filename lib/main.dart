import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/theme/app_theme.dart';
import 'package:mtc2026/ui/screens/home_screen.dart';
import 'package:mtc2026/ui/screens/company_login_screen.dart';
import 'package:mtc2026/utils/notification_service.dart';
import 'package:mtc2026/utils/responsive.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Conditional import to handle Desktop vs Web safely
import 'package:mtc2026/platform_init_desktop.dart' 
    if (dart.library.html) 'package:mtc2026/platform_init_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      center: true,
      title: 'MTC 2026 ERP',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // Set prevent close only in release mode to avoid locking the IDE process during development
      if (kReleaseMode) {
        await windowManager.setPreventClose(true);
      }
    });
  }

  // This call will execute Desktop initialization on Windows/Linux
  // and do nothing on Web, ensuring no crashes.
  initializePlatform();
  await NotificationService().init();

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

class MyApp extends StatefulWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final shouldClose = await _showExitDialog();
    if (shouldClose == true) {
      await windowManager.destroy();
    }
  }

  Future<bool?> _showExitDialog() async {
    final context = navigatorKey.currentContext;
    if (context == null) return true;

    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text("ΚΛΕΙΣΙΜΟ ΕΦΑΡΜΟΓΗΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: const Text(
          "Έχετε κάνει συγχρονισμό (Upload στο Cloud) των τελευταίων σας αλλαγών;\n\nΑν δεν το κάνατε, μπορεί να χαθούν τα τελευταία δεδομένα από άλλες συσκευές.",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), 
            child: const Text("ΑΚΥΡΩΣΗ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("ΕΞΟΔΟΣ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'MTC 2026',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: projectProvider.settings.appTheme == 'DARK'
              ? ThemeMode.dark
              : projectProvider.settings.appTheme == 'LIGHT'
                  ? ThemeMode.light
                  : ThemeMode.system,
          home: widget.startScreen,
        );
      },
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
