import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class WakaTextStyles {
  static const headlineLarge = TextStyle(
    color: WakaColors.text,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    height: 1.04,
    letterSpacing: 0,
  );

  static const headlineMedium = TextStyle(
    color: WakaColors.text,
    fontSize: 22.5,
    fontWeight: FontWeight.w900,
    height: 1.08,
    letterSpacing: 0,
  );

  static const titleLarge = TextStyle(
    color: WakaColors.text,
    fontSize: 20.5,
    fontWeight: FontWeight.w900,
    height: 1.12,
  );

  static const titleMedium = TextStyle(
    color: WakaColors.text,
    fontSize: 16.5,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  static const bodyLarge = TextStyle(
    color: WakaColors.text,
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.18,
  );

  static const bodyMedium = TextStyle(
    color: WakaColors.mutedText,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.18,
  );

  static const navLabel = TextStyle(
    color: WakaColors.mutedText,
    fontSize: 11.8,
    fontWeight: FontWeight.w500,
    height: 1.05,
  );

  static const profileSectionTitle = TextStyle(
    color: WakaColors.text,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    height: 1.08,
  );

  static const profileMenuItem = TextStyle(
    color: WakaColors.text,
    fontSize: 21,
    fontWeight: FontWeight.w500,
    height: 1,
  );

  static const labelMedium = TextStyle(
    color: WakaColors.mutedText,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );
}
