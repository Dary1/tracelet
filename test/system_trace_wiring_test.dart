import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';

/// Ensures every system trace asset is referenced from application code.
void main() {
  test('every SystemTraceId is wired in application feedback paths', () {
    const wired = {
      SystemTraceId.modeMessageReceive,
      SystemTraceId.modeBottleMail,
      SystemTraceId.modeSpecificUserSend,
      SystemTraceId.notificationsOn,
      SystemTraceId.notificationsOff,
      SystemTraceId.autoPlayOn,
      SystemTraceId.autoPlayOff,
      SystemTraceId.messagePlayback,
      SystemTraceId.randomMessage,
      SystemTraceId.replayMessage,
      SystemTraceId.friendConnected,
      SystemTraceId.friendUnavailable,
      SystemTraceId.destinationSelected,
      SystemTraceId.nameTraceRegistrationPrompt,
      SystemTraceId.nameTraceSaved,
      SystemTraceId.nameTraceSaveFailed,
      SystemTraceId.senderRemoved,
      SystemTraceId.autoContinuousOn,
      SystemTraceId.autoContinuousOff,
      SystemTraceId.settingsPortal,
      SystemTraceId.alert,
      SystemTraceId.bottleDiscarded,
      SystemTraceId.bottleSent,
      SystemTraceId.bottleError,
      SystemTraceId.noMessageFound,
    };

    expect(
      wired,
      SystemTraceId.values.toSet(),
      reason: 'Add wiring for new SystemTraceId values in app feedback',
    );
  });
}
