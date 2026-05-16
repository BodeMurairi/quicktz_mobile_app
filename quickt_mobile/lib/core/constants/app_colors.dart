import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFE7F0FA);
  static const Color secondary = Color(0xFF7BA4D0);
  static const Color primary = Color(0xFF2E5E99);
  static const Color darkPrimary = Color(0xFF0D2440);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF4F7FB);
  static const Color grey = Color(0xFF8FA3BC);
  static const Color textDark = Color(0xFF0D2440);
  static const Color textMedium = Color(0xFF2E5E99);
  static const Color textLight = Color(0xFF7BA4D0);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkPrimary, primary],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}
