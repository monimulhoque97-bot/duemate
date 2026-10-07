import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  runApp(const DueMateApp());
}

class DueMateApp extends StatelessWidget {
  const DueMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DueMate',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
