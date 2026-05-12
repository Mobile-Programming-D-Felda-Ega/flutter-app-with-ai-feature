import 'package:flutter/material.dart';

/// Central color palette for StudyLink AI.
/// Extracted from the Stitch UI design system.
abstract final class AppColors {
  // ─── Primary ───
  static const Color primary = Color(0xFF4A3AFF);
  static const Color primaryLight = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF3A2ED4);

  // ─── Surface & Background ───
  static const Color background = Color(0xFFFAFAFE);
  static const Color surface = Colors.white;
  static const Color surfacePurple = Color(0xFFF5F3FF);
  static const Color surfacePurpleLight = Color(0xFFFAF8FF);

  // ─── Card ───
  static const Color cardBorder = Color(0xFFE0D7FE);
  static const Color cardBorderLight = Color(0xFFEDE9FE);

  // ─── Text ───
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // ─── Semantic ───
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Bottom Nav ───
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF9CA3AF);

  // ─── Misc ───
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmer = Color(0xFFE0D7FE);
  static const Color shadow = Color(0x1A000000);

  // ─── Notification dot ───
  static const Color notificationDot = Color(0xFFEF4444);
}
