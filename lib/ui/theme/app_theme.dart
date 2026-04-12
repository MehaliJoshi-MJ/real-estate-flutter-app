import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF1B4D3E);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0),
  );
}
