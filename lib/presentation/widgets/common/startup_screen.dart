import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';
import 'package:tracelet/presentation/theme/tracelet_typography.dart';
import 'package:tracelet/presentation/widgets/common/tracelet_scaffold.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return TraceletCanvasScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (message != null) ...[
              const SizedBox(height: TraceletSpacing.startupMessageGap),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TraceletSpacing.screenPadding,
                ),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TraceletTypography.startupMessage(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
