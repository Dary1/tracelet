import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/app_state.dart';
import 'package:tracelet/application/device_feedback.dart';
import 'package:tracelet/application/auth_providers.dart';
import 'package:tracelet/application/repository_providers.dart';
import 'package:tracelet/application/trace_canvas_notifier.dart';
import 'package:tracelet/data/repositories/asset_system_trace_repository.dart';
import 'package:tracelet/data/api/tracelet_api_client.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';
import 'package:tracelet/domain/models/app_mode.dart';
import 'package:tracelet/domain/models/app_settings.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/hardware/button_input.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/presentation/feedback/visual_cue_type.dart';

class AppStateNotifier extends Notifier<AppState> {
  int _destinationIndex = 0;
  @override
  AppState build() => const AppState();

  DeviceFeedback get _feedback => ref.read(deviceFeedbackProvider);

  Future<void> initialize() async {
    final settings =
        await ref.read(settingsRepositoryProvider).loadSettings();
    final lastMessage =
        await ref.read(messageRepositoryProvider).getLastReceivedMessage();
    final destinations =
        await ref.read(userRepositoryProvider).getDestinationUsers();
    final destination = destinations.isEmpty
        ? null
        : destinations[_destinationIndex.clamp(0, destinations.length - 1)];

    state = state.copyWith(
      settings: settings,
      lastReceivedMessage: lastMessage,
      currentDestination: destination,
    );
  }

  Future<void> handleButtonAction(
    VirtualButton button,
    ButtonGesture gesture,
  ) async {
    switch (gesture) {
      case ButtonGesture.simultaneousTap:
        await _onSimultaneousTap();
      case ButtonGesture.simultaneousLongPress:
        await _onSimultaneousLongPress();
      case ButtonGesture.tap:
      case ButtonGesture.longPress:
        if (button == VirtualButton.a) {
          await _onButtonA(gesture);
        } else {
          await _onButtonB(gesture);
        }
    }
  }

  Future<void> _onButtonA(ButtonGesture gesture) async {
    if (state.mode == AppMode.nameTraceRegistration) {
      if (gesture == ButtonGesture.tap) {
        await _feedback.buttonA(gesture: gesture);
        final saved = await _saveNameTraceRegistration();
        if (saved) {
          _feedback.overlay(VisualCueType.nameTraceSaved);
          await _feedback.trace(SystemTraceId.nameTraceSaved, clearFirst: false);
        } else {
          await _feedback.alert();
        }
        state = state.copyWith(mode: AppMode.specificUserSend);
      }
      return;
    }

    switch (gesture) {
      case ButtonGesture.tap:
        await _feedback.buttonA(gesture: gesture);
        final nextMode = state.mode.nextPrimaryMode();
        state = state.copyWith(mode: nextMode);
        _feedback.overlay(VisualCueType.modeChange, mode: nextMode);
        await _feedback.trace(
          ref.read(systemTraceRepositoryProvider).modeTrace(nextMode),
          mode: nextMode,
        );
      case ButtonGesture.longPress:
        await _feedback.buttonA(gesture: gesture);
        await _toggleNotifications();
      default:
        break;
    }
  }

  Future<void> _onButtonB(ButtonGesture gesture) async {
    if (state.mode == AppMode.nameTraceRegistration) return;

    switch (state.mode) {
      case AppMode.messageReceive:
        await _onMessageReceiveB(gesture);
      case AppMode.bottleMail:
        await _onBottleMailB(gesture);
      case AppMode.specificUserSend:
        await _onSpecificUserSendB(gesture);
      case AppMode.nameTraceRegistration:
        break;
    }
  }

  Future<void> _onMessageReceiveB(ButtonGesture gesture) async {
    switch (gesture) {
      case ButtonGesture.tap:
        await _feedback.buttonB(gesture: gesture);
        await _playNextMessage();
      case ButtonGesture.longPress:
        await _feedback.buttonB(gesture: gesture);
        await _toggleAutoPlay();
      default:
        break;
    }
  }

  Future<void> _onBottleMailB(ButtonGesture gesture) async {
    switch (gesture) {
      case ButtonGesture.tap:
        await _feedback.buttonB(gesture: gesture);
        await _receiveRandomMessage();
      case ButtonGesture.longPress:
        await _feedback.buttonB(gesture: gesture);
        await _connectFriend();
      default:
        break;
    }
  }

  Future<void> _onSpecificUserSendB(ButtonGesture gesture) async {
    switch (gesture) {
      case ButtonGesture.tap:
        await _feedback.buttonB(gesture: gesture);
        await _replayLastMessage();
      case ButtonGesture.longPress:
        await _feedback.buttonB(gesture: gesture);
        await _switchDestination();
      default:
        break;
    }
  }

  Future<void> _onSimultaneousTap() async {
    await _feedback.buttonA(gesture: ButtonGesture.simultaneousTap);

    switch (state.mode) {
      case AppMode.messageReceive:
        await _removeLastSender();
      case AppMode.bottleMail:
        await _toggleAutoContinuous();
      case AppMode.specificUserSend:
      case AppMode.nameTraceRegistration:
        _feedback.overlay(VisualCueType.settingsTransition);
        await _feedback.trace(SystemTraceId.settingsPortal);
        ref.read(openSettingsProvider.notifier).state = true;
    }
  }

  Future<void> _onSimultaneousLongPress() async {
    await _feedback.buttonA(gesture: ButtonGesture.simultaneousLongPress);

    if (state.mode != AppMode.specificUserSend) return;

    _feedback.overlay(VisualCueType.nameTraceRegistration);
    state = state.copyWith(mode: AppMode.nameTraceRegistration);
    ref.read(traceCanvasProvider.notifier).clear();
    await _feedback.trace(SystemTraceId.nameTraceRegistrationPrompt);
  }

  Future<void> _toggleNotifications() async {
    final enabled = !state.settings.notificationsEnabled;
    final updated = state.settings.copyWith(notificationsEnabled: enabled);
    await _persistSettings(updated);
    await _feedback.toggle(
      enabled: enabled,
      overlayCue: VisualCueType.toggleNotifications,
      onTrace: SystemTraceId.notificationsOn,
      offTrace: SystemTraceId.notificationsOff,
    );
  }

  Future<void> _toggleAutoPlay() async {
    final enabled = !state.settings.autoPlayEnabled;
    final updated = state.settings.copyWith(autoPlayEnabled: enabled);
    await _persistSettings(updated);
    await _feedback.toggle(
      enabled: enabled,
      overlayCue: VisualCueType.toggleAutoPlay,
      onTrace: SystemTraceId.autoPlayOn,
      offTrace: SystemTraceId.autoPlayOff,
    );
  }

  Future<void> _toggleAutoContinuous() async {
    final enabled = !state.settings.autoContinuousReceiveEnabled;
    final updated = state.settings.copyWith(autoContinuousReceiveEnabled: enabled);
    await _persistSettings(updated);
    await _feedback.toggle(
      enabled: enabled,
      overlayCue: VisualCueType.toggleAutoContinuous,
      onTrace: SystemTraceId.autoContinuousOn,
      offTrace: SystemTraceId.autoContinuousOff,
    );
  }

  Future<void> _playNextMessage() async {
    final message =
        await ref.read(messageRepositoryProvider).getNextUnplayedMessage();
    if (message == null) {
      await _feedback.noMessageFound();
      return;
    }
    await _playMessage(message);
  }

  Future<void> _receiveRandomMessage() async {
    if (!state.settings.canReceiveRandomMessage) {
      await _feedback.noMessageFound();
      return;
    }

    try {
      final message =
          await ref.read(messageRepositoryProvider).receiveRandomMessage();
      final updated = state.settings.copyWith(
        dailyRandomReceiveCount: state.settings.dailyRandomReceiveCount + 1,
      );
      await _persistSettings(updated);
      await _playMessage(message);
    } on NoBottleAvailableException {
      await _feedback.noMessageFound();
    } on BottleMailException {
      await _feedback.trace(SystemTraceId.bottleError, clearFirst: false);
    } on TraceletApiException {
      await _feedback.trace(SystemTraceId.bottleError, clearFirst: false);
    }
  }

  Future<void> _replayLastMessage() async {
    final message = state.lastReceivedMessage ??
        await ref.read(messageRepositoryProvider).getLastReceivedMessage();
    if (message == null) {
      await _feedback.noMessageFound();
      return;
    }
    await _playMessage(message);
  }

  Future<void> _playMessage(TraceMessage message) async {
    state = state.copyWith(lastReceivedMessage: message);
    if (message.points.isNotEmpty) {
      await _feedback.playReceivedMessage(message);
    } else {
      await _feedback.noMessageFound();
    }
    await ref.read(messageRepositoryProvider).markAsPlayed(message.id);
  }

  Future<void> _connectFriend() async {
    final lastUser = state.lastReceivedMessage?.sender;
    if (lastUser == null) {
      await _feedback.alert();
      await _feedback.trace(SystemTraceId.friendUnavailable);
      return;
    }

    final userRepo = ref.read(userRepositoryProvider);
    await userRepo.sendFriendRequest(lastUser.id);
    await userRepo.acceptFriendRequest(lastUser.id);

    _feedback.overlay(VisualCueType.friendConnected);
    await _feedback.trace(SystemTraceId.friendConnected);
  }

  Future<void> _removeLastSender() async {
    final sender = state.lastReceivedMessage?.sender;
    if (sender == null) {
      await _feedback.alert();
      return;
    }

    await ref.read(userRepositoryProvider).deleteFriend(sender.id);
    _feedback.overlay(VisualCueType.senderRemoved);
    await _feedback.trace(SystemTraceId.senderRemoved);
  }

  Future<void> _switchDestination() async {
    final destinations =
        await ref.read(userRepositoryProvider).getDestinationUsers();
    if (destinations.isEmpty) {
      await _feedback.alert();
      return;
    }

    _destinationIndex = (_destinationIndex + 1) % destinations.length;
    final next = destinations[_destinationIndex];
    state = state.copyWith(currentDestination: next);

    if (next.nameTracePoints.isNotEmpty) {
      _feedback.overlay(VisualCueType.messagePlayStart);
      await ref.read(traceCanvasProvider.notifier).playNameTrace(next);
    } else {
      _feedback.overlay(VisualCueType.destinationSwitch);
      await _feedback.trace(SystemTraceId.destinationSelected);
    }
  }

  Future<void> toggleMute(bool muted) async {
    final updated = state.settings.copyWith(muted: muted);
    await _persistSettings(updated);
  }

  Future<void> setTraceProfilePreset(TraceProfilePreset preset) async {
    final updated = state.settings.copyWith(traceProfilePreset: preset);
    await _persistSettings(updated);
  }

  Future<void> _persistSettings(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).saveSettings(settings);
    state = state.copyWith(settings: settings);
  }

  Future<bool> _saveNameTraceRegistration() async {
    final destination = state.currentDestination;
    if (destination == null) return false;

    final points = ref.read(traceCanvasProvider.notifier).captureStrokePoints();
    final drawable = points.where((point) => !point.isBreak).toList();
    if (drawable.isEmpty) return false;

    final start = drawable.first.timestamp;
    final samples = <({double dx, double dy, int msSinceStart})>[];
    for (final point in drawable) {
      samples.add((
        dx: point.position.dx,
        dy: point.position.dy,
        msSinceStart: point.timestamp.difference(start).inMilliseconds,
      ));
    }

    final updated = destination.copyWith(nameTracePoints: samples);
    await ref.read(userRepositoryProvider).saveNameTrace(destination.id, updated);
    state = state.copyWith(currentDestination: updated);
    return true;
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

final bootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(authNotifierProvider.future);
  await ref.read(systemTraceRepositoryProvider).loadAll();
  await ref.read(backendServicesProvider.future);
  await ref.read(appStateProvider.notifier).initialize();
});

final openSettingsProvider = StateProvider<bool>((ref) => false);
