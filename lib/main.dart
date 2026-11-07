import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Always set up notifications (permission, sound channel, listeners) on phone
  if (!kIsWeb) {
    await PushNotificationService.initialize();
  }

  // Load Khmer / English month and day names
  await initializeDateFormatting();

  // Load the saved language (English by default)
  final languageProvider = LanguageProvider();
  await languageProvider.load();

  final authProvider = AuthProvider();

  // Check whether a valid JWT already exists.
  await authProvider.restoreSession();

  // Already logged in: send this phone's token to the server
  if (!kIsWeb && authProvider.isAuthenticated) {
    await PushNotificationService.registerToken();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    final bool isLoggedIn = authProvider.isAuthenticated;

    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: isLoggedIn ? themeProvider.themeMode : ThemeMode.light,

      // =====================================================
      // LANGUAGE
      // =====================================================
      locale: languageProvider.locale,
      supportedLocales: const [Locale('en'), Locale('km')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // =====================================================
      // LIGHT THEME
      // =====================================================
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0061B7),
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: Colors.black,
          onSurfaceVariant: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          titleSmall: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
      ),

      // =====================================================
      // DARK THEME
      // =====================================================
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0061B7),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E2630),
          onSurface: Colors.white,
          onSurfaceVariant: Colors.white70,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleSmall: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white60),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}