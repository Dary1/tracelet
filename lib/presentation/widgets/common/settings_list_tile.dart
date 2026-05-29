import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_shapes.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';
import 'package:tracelet/presentation/theme/tracelet_typography.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: TraceletSpacing.listHorizontal,
        vertical: compact ? 4 : TraceletSpacing.listVertical,
      ),
      leading: _SettingsIconBadge(icon: icon, color: tokens.textMuted),
      title: Text(title, style: TraceletTypography.listTitle(context)),
      subtitle: Text(
        subtitle,
        style: TraceletTypography.listSubtitle(context),
      ),
      shape: compact
          ? null
          : RoundedRectangleBorder(
              borderRadius: TraceletShapes.listTileRadius,
            ),
      onTap: onTap,
    );
  }
}

class _SettingsIconBadge extends StatelessWidget {
  const _SettingsIconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
