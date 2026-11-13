import 'package:flutter/material.dart';

const kInk = Color(0xFF1F2A3C);      // steel navy: nav, headings
const kAccent = Color(0xFFE8A317);   // safety amber: primary actions
const kBg = Color(0xFFF4F6F8);
const kLine = Color(0xFFE3E7ED);
const kMuted = Color(0xFF66758A);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kInk,
    primary: kInk,
    secondary: kAccent,
    surface: Colors.white,
  );
  OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: kLine)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: b(kLine),
      enabledBorder: b(kLine),
      focusedBorder: b(kInk),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kInk,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kInk,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: kLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFFFF1CF),
      selectedIconTheme: IconThemeData(color: kInk),
      selectedLabelTextStyle: TextStyle(color: kInk, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: kMuted),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFFFF1CF),
    ),
    dividerColor: kLine,
  );
}
