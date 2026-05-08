import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/pdv_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dairy - PDV',
      theme: AppTheme.lightTheme,
      home: const Dairy(),
      debugShowCheckedModeBanner: false,
    );
  }
}

