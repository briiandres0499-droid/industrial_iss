import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/app_selector_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // El panel de control es ahora lo primero que ve el usuario.
      // Desde ahí se elige entre la app Industrial y el Rastreador ISS.
      home: const AppSelectorScreen(),
    );
  }
}
