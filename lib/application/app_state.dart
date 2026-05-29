import 'package:tracelet/domain/models/app_mode.dart';
import 'package:tracelet/domain/models/app_settings.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/user.dart';

/// Immutable snapshot of the Tracelet virtual-hardware state machine.
class AppState {
  const AppState({
    this.mode = AppMode.messageReceive,
    this.settings = const AppSettings(),
    this.lastReceivedMessage,
    this.currentDestination,
  });

  final AppMode mode;
  final AppSettings settings;
  final TraceMessage? lastReceivedMessage;
  final TraceUser? currentDestination;

  AppState copyWith({
    AppMode? mode,
    AppSettings? settings,
    TraceMessage? lastReceivedMessage,
    TraceUser? currentDestination,
    bool clearLastMessage = false,
  }) {
    return AppState(
      mode: mode ?? this.mode,
      settings: settings ?? this.settings,
      lastReceivedMessage: clearLastMessage
          ? null
          : (lastReceivedMessage ?? this.lastReceivedMessage),
      currentDestination: currentDestination ?? this.currentDestination,
    );
  }
}
