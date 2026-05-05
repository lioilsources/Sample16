import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

class Smpl16App extends StatelessWidget {
  const Smpl16App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMPL–16',
      theme: AppTheme.dark,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
