import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryLight = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
}

class AppTextStyles {
  static const heading = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87);
  static const subheading = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87);
  static const bodyText = TextStyle(fontSize: 16, color: Colors.black87);
  static const bodyLarge = TextStyle(fontSize: 18, color: Colors.black87);
  static const captionText = TextStyle(fontSize: 12, color: Colors.grey);
  static const subtitle = TextStyle(fontSize: 14, color: Colors.black54);
}

class AppPaddings {
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
}
