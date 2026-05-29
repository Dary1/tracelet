import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_shapes.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';
import 'package:tracelet/presentation/theme/tracelet_typography.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

/// Groups settings rows under an optional section header inside a subtle surface.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TraceletSpacing.listHorizontal,
        TraceletSpacing.listSectionTop,
        TraceletSpacing.listHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 4,
                bottom: TraceletSpacing.itemGap,
              ),
              child: Text(
                title!,
                style: TraceletTypography.sectionHeader(context),
              ),
            ),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: TraceletShapes.listTileRadius,
            ),
            child: ClipRRect(
              borderRadius: TraceletShapes.listTileRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _interleaveDividers(context, children),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _interleaveDividers(BuildContext context, List<Widget> items) {
    if (items.length <= 1) return items;

    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(
          Divider(
            height: 1,
            indent: TraceletSpacing.listHorizontal,
            endIndent: TraceletSpacing.listHorizontal,
            color: Theme.of(context).dividerTheme.color,
          ),
        );
      }
    }
    return result;
  }
}
