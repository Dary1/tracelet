import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/auth_providers.dart';
import 'package:tracelet/domain/auth/social_provider.dart';
import 'package:tracelet/domain/auth/social_sign_in_unavailable_exception.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';
import 'package:tracelet/presentation/theme/tracelet_typography.dart';
import 'package:tracelet/presentation/widgets/common/social_sign_in_button.dart';
import 'package:tracelet/presentation/widgets/common/tracelet_scaffold.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider).value;
    final hostedUi = ref.watch(cognitoHostedUiAuthProvider);
    final error = auth?.errorMessage;

    return TraceletScaffold(
      title: 'Account',
      body: ListView(
        padding: const EdgeInsets.all(TraceletSpacing.screenPadding),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              auth?.accountLabel ?? 'Guest',
              style: TraceletTypography.screenTitle(context),
            ),
            subtitle: Text(
              auth?.isSignedIn == true
                  ? 'Your traces sync to your account'
                  : 'Browsing as guest — sign in to keep friends and settings across devices',
              style: TraceletTypography.bodyMuted(context),
            ),
          ),
          const SizedBox(height: TraceletSpacing.sectionGap),
          if (auth?.isSignedIn == true) ...[
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                        () => ref
                            .read(authNotifierProvider.notifier)
                            .revertToGuest(),
                      ),
              child: const Text('Continue as guest'),
            ),
          ] else ...[
            SocialSignInButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata,
              enabled: !_busy && hostedUi.isGoogleConfigured,
              onPressed: () => _signIn(SocialProvider.google),
            ),
            const SizedBox(height: TraceletSpacing.itemGap),
            SocialSignInButton(
              label: 'Continue with Apple',
              icon: Icons.apple,
              enabled: !_busy && hostedUi.isAppleConfigured,
              onPressed: () => _signIn(SocialProvider.apple),
            ),
            if (!hostedUi.isGoogleConfigured || !hostedUi.isAppleConfigured) ...[
              const SizedBox(height: 20),
              Text(
                'Social sign-in requires Google and Apple to be configured in Cognito. '
                'You can keep using Tracelet as a guest until then.',
                style: TraceletTypography.listSubtitle(context).copyWith(
                  fontSize: 13,
                ),
              ),
            ],
          ],
          if (error != null) ...[
            const SizedBox(height: 20),
            Text(error, style: TraceletTypography.error(context)),
          ],
        ],
      ),
    );
  }

  Future<void> _signIn(SocialProvider provider) async {
    await _run(() async {
      try {
        await ref.read(authNotifierProvider.notifier).signInWithSocial(provider);
      } on SocialSignInUnavailableException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    });
  }
}
