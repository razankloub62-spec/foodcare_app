import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final ValueNotifier<Color> themeColor = ValueNotifier<Color>(const Color(0xFFFF8FAB));
  static const String _themeKey = 'selected_theme_color';

  static const List<Color> availableColors = [
    Color(0xFFFF8FAB), // وردي ناعم
    Color(0xFFC77DFF), // لافندر / بنفسجي فاتح
    Color(0xFFFFB5A7), // خوخي دافئ
    Color(0xFF80ED99), // نعناعي هادئ
    Color(0xFFFAD2E1), // وردي باستيل فاتح
  ];

  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColorValue = prefs.getInt(_themeKey);
    if (savedColorValue != null) {
      themeColor.value = Color(savedColorValue);
    }
  }

  static Future<void> updateTheme(Color newColor) async {
    themeColor.value = newColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, newColor.toARGB32());
  }
}