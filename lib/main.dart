// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: const DelcomTodosApp(),
    ),
  );
}

class DelcomTodosApp extends StatefulWidget {
  const DelcomTodosApp({super.key});

  @override
  State<DelcomTodosApp> createState() => _DelcomTodosAppState();
}

class _DelcomTodosAppState extends State<DelcomTodosApp> {
  late final _router = buildRouter(context);

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp.router(
      title: 'Delcom Todos',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildLightTheme() {
    // Nebula Light: deep violet/indigo tones with cosmic accents
    const seedColor = Color(0xFF6C3DE1);  // Deep violet
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: const Color(0xFF6C3DE1),       // Deep violet
      onPrimary: Colors.white,
      secondary: const Color(0xFFE040C8),     // Nebula magenta
      onSecondary: Colors.white,
      tertiary: const Color(0xFF00C2FF),      // Star blue
      onTertiary: Colors.white,
      surface: const Color(0xFFF5F3FF),       // Soft lavender white
      onSurface: const Color(0xFF1A1035),
      surfaceContainerHighest: const Color(0xFFEBE7FF),
    );
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF0EEFF),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color(0xFFEFEBFF).withOpacity(0.8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFF6C3DE1).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C3DE1), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFEFEBFF).withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: const Color(0xFF6C3DE1),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C3DE1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF6C3DE1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6C3DE1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFFEEEAFF).withOpacity(0.95),
        indicatorColor: const Color(0xFF6C3DE1).withOpacity(0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF6C3DE1));
          }
          return const IconThemeData(color: Color(0xFF8A7AAF));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: Color(0xFF6C3DE1), fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: Color(0xFF8A7AAF), fontSize: 12);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1A1035),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF6C3DE1)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF6C3DE1);
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF6C3DE1).withOpacity(0.4);
          }
          return null;
        }),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    // Nebula Dark: deep space background with glowing cosmic colors
    const seedColor = Color(0xFF9D6FFF);  // Bright nebula purple
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: const Color(0xFF9D6FFF),       // Nebula violet
      onPrimary: Colors.white,
      secondary: const Color(0xFFFF6EE7),     // Hot pink nebula
      onSecondary: Colors.white,
      tertiary: const Color(0xFF00D4FF),      // Star cluster blue
      surface: const Color(0xFF0E0A1E),       // Deep space
      onSurface: const Color(0xFFE8E0FF),
      surfaceContainerHighest: const Color(0xFF1A1535),
    );
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF080514),  // Deep space black
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color(0xFF160F2E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D2A6B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9D6FFF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1535),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: const Color(0xFF9D6FFF),
        labelStyle: const TextStyle(color: Color(0xFF9D6FFF)),
        hintStyle: TextStyle(color: const Color(0xFFE8E0FF).withOpacity(0.4)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C3DE1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF9D6FFF),
          side: const BorderSide(color: Color(0xFF9D6FFF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF9D6FFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF0E0A1E),
        indicatorColor: const Color(0xFF9D6FFF).withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF9D6FFF));
          }
          return const IconThemeData(color: Color(0xFF5A4A7A));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: Color(0xFF9D6FFF), fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: Color(0xFF5A4A7A), fontSize: 12);
        }),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF080514),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFE8E0FF),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: Color(0xFF9D6FFF)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF9D6FFF);
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF9D6FFF).withOpacity(0.4);
          }
          return null;
        }),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF160F2E),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF1A1535),
      ),
    );
  }
}