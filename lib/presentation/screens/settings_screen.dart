import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/app_state_notifier.dart';
import 'package:tracelet/application/auth_providers.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';
import 'package:tracelet/presentation/screens/account_screen.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';
import 'package:tracelet/presentation/theme/tracelet_typography.dart';
import 'package:tracelet/presentation/widgets/common/settings_list_tile.dart';
import 'package:tracelet/presentation/widgets/common/settings_section.dart';
import 'package:tracelet/presentation/widgets/common/tracelet_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStateProvider).settings;
    final auth = ref.watch(authNotifierProvider).value;

    return TraceletScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.only(bottom: TraceletSpacing.sectionGap),
        children: [
          SettingsSection(
            children: [
              SettingsListTile(
                title: 'Profile QR',
                subtitle: 'Share your Tracelet identity',
                icon: Icons.qr_code_2_outlined,
                onTap: () {},
                compact: true,
              ),
              SettingsListTile(
                title: 'Billing',
                subtitle: settings.isSubscribed ? 'Subscribed' : 'Free plan',
                icon: Icons.payment_outlined,
                onTap: () {},
                compact: true,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TraceletSpacing.listHorizontal,
                  vertical: TraceletSpacing.listVertical,
                ),
                title: Text('Mute', style: TraceletTypography.listTitle(context)),
                subtitle: Text(
                  settings.muted ? 'Haptics muted' : 'Haptics enabled',
                  style: TraceletTypography.listSubtitle(context),
                ),
                value: settings.muted,
                activeThumbColor: Theme.of(context).colorScheme.onSurface,
                onChanged: (value) {
                  ref.read(appStateProvider.notifier).toggleMute(value);
                },
              ),
              SettingsListTile(
                title: 'Account',
                subtitle: auth?.accountLabel ?? 'Guest',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountScreen(),
                    ),
                  );
                },
                compact: true,
              ),
            ],
          ),
          SettingsSection(
            title: 'Trace style',
            children: [
              ...TraceProfilePreset.values
                  .where((p) => p != TraceProfilePreset.custom)
                  .map(
                (preset) => RadioListTile<TraceProfilePreset>(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TraceletSpacing.listHorizontal,
                    vertical: 4,
                  ),
                  title: Text(
                    preset.label,
                    style: TraceletTypography.listTitle(context),
                  ),
                  subtitle: Text(
                    preset.description,
                    style: TraceletTypography.listSubtitle(context).copyWith(
                      fontSize: 12,
                    ),
                  ),
                  value: preset,
                  groupValue: settings.traceProfilePreset,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(appStateProvider.notifier)
                        .setTraceProfilePreset(value);
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Preferences',
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TraceletSpacing.listHorizontal,
                  vertical: TraceletSpacing.listVertical,
                ),
                title: Text(
                  'Notifications',
                  style: TraceletTypography.metaLabel(context),
                ),
                trailing: Text(
                  settings.notificationsEnabled ? 'ON' : 'OFF',
                  style: TraceletTypography.metaValue(context),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TraceletSpacing.listHorizontal,
                  vertical: TraceletSpacing.listVertical,
                ),
                title: Text(
                  'Auto-play',
                  style: TraceletTypography.metaLabel(context),
                ),
                trailing: Text(
                  settings.autoPlayEnabled ? 'ON' : 'OFF',
                  style: TraceletTypography.metaValue(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
