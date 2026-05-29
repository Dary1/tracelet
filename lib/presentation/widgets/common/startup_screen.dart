import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';
import 'package:tracelet/presentation/theme/tracelet_typography.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';
import 'package:tracelet/presentation/widgets/common/tracelet_scaffold.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    final hasError = message != null;

    return TraceletCanvasScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TraceletSpacing.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tracelet', style: TraceletTypography.brandMark(context)),
              const SizedBox(height: TraceletSpacing.sectionGap),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: hasError ? tokens.error : tokens.textMuted,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: TraceletSpacing.startupMessageGap),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: hasError
                      ? TraceletTypography.error(context)
                      : TraceletTypography.startupMessage(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
