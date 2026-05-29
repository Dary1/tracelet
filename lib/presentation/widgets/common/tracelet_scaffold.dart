import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

/// Shared scaffold for secondary screens (settings, account).
class TraceletScaffold extends StatelessWidget {
  const TraceletScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.surfaceBackground,
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerTheme.color,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: body,
      ),
    );
  }
}

/// Canvas shell — pure black, no app bar.
class TraceletCanvasScaffold extends StatelessWidget {
  const TraceletCanvasScaffold({
    super.key,
    required this.body,
  });

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvasBackground,
      body: body,
    );
  }
}
