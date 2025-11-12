import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF282A36);
  static const Color currentLine = Color(0xFF44475A);
  static const Color foreground = Color(0xFFF8F8F2);
  static const Color comment = Color(0xFF6272A4);
  static const Color cyan = Color(0xFF8BE9FD);
  static const Color green = Color(0xFF50FA7B);
  static const Color orange = Color(0xFFFFB86C);
  static const Color pink = Color(0xFFFF79C6);
  static const Color purple = Color(0xFFBD93F9);
  static const Color red = Color(0xFFFF5555);
  static const Color yellow = Color(0xFFF1FA8C);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: purple,
      cardColor: currentLine,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: foreground),
        bodyMedium: TextStyle(color: foreground),
        displayLarge: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: cyan, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: green),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: currentLine,
        foregroundColor: foreground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: foreground,
        ),
      ),
    );
  }
}