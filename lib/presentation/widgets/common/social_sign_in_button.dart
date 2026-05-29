import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';

class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: FilledButton.styleFrom(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: TraceletSpacing.screenPadding,
        ),
      ),
    );
  }
}
