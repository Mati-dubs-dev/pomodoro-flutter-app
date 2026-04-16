import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/pomodoro_provider.dart';
import 'screens/pomodoro_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios antes de levantar la app
  await NotificationService.initialize();
  final storage = await StorageService.create();

  runApp(
    ProviderScope(
      overrides: [
        // Inyectar la instancia de StorageService ya inicializada
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const PomodoroApp(),
    ),
  );
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B6B),
          secondary: Color(0xFF4ECDC4),
          surface: Color(0xFF1a1a2e),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFFFF6B6B)
                : Colors.grey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFFFF6B6B).withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
      home: const PomodoroScreen(),
    );
  }
}