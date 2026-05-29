import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

/// Text styles derived from the active theme and visual tokens.
abstract final class TraceletTypography {
  static TextStyle screenTitle(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          color: tokens.textPrimary,
        ) ??
        TextStyle(color: tokens.textPrimary, fontSize: 20);
  }

  static TextStyle listTitle(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(color: tokens.textSecondary);
  }

  static TextStyle listSubtitle(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tokens.textSubtle,
        ) ??
        TextStyle(color: tokens.textSubtle);
  }

  static TextStyle sectionHeader(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          color: tokens.textMuted,
        ) ??
        TextStyle(color: tokens.textMuted);
  }

  static TextStyle metaLabel(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return TextStyle(
      color: tokens.textMuted,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    );
  }

  static TextStyle metaValue(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return TextStyle(
      color: tokens.textSubtle,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
  }

  static TextStyle bodyMuted(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.textMuted,
        ) ??
        TextStyle(color: tokens.textMuted);
  }

  static TextStyle error(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tokens.error,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(color: tokens.error);
  }

  static TextStyle startupMessage(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.textMuted,
        ) ??
        TextStyle(color: tokens.textMuted);
  }

  static TextStyle brandMark(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          color: tokens.textPrimary,
          fontSize: 22,
          letterSpacing: -0.4,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: tokens.textPrimary,
          fontSize: 22,
          letterSpacing: -0.4,
          fontWeight: FontWeight.w600,
        );
  }
}
