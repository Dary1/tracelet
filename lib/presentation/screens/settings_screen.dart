import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/app_state_notifier.dart';
import 'package:tracelet/application/auth_providers.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';
import 'package:tracelet/presentation/screens/account_screen.dart';
import 'package:tracelet/presentation/theme/tracelet_spacing.dart';
import 'package:tracelet/presentation/theme/tracelet_typography.dart';
import 'package:tracelet/presentation/widgets/common/settings_list_tile.dart';
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
        children: [
          SettingsListTile(
            title: 'Profile QR',
            subtitle: 'Share your Tracelet identity',
            icon: Icons.qr_code_2_outlined,
            onTap: () {},
          ),
          SettingsListTile(
            title: 'Billing',
            subtitle: settings.isSubscribed ? 'Subscribed' : 'Free plan',
            icon: Icons.payment_outlined,
            onTap: () {},
          ),
          SwitchListTile(
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
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TraceletSpacing.listHorizontal,
              TraceletSpacing.listVertical,
              TraceletSpacing.listHorizontal,
              0,
            ),
            child: Text(
              'Trace style',
              style: TraceletTypography.sectionHeader(context),
            ),
          ),
          ...TraceProfilePreset.values
              .where((p) => p != TraceProfilePreset.custom)
              .map(
            (preset) => RadioListTile<TraceProfilePreset>(
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
          const Divider(),
          ListTile(
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
    );
  }
}
