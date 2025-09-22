import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5));
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: Brightness.light,
  );
}
