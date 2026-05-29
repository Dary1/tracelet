/// Tests that "played message" and "realtime trace replay" are the same *process*
/// (point-by-point timing) — not a final canvas screenshot.
import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';
import 'package:tracelet/data/local/memory_message_inbox.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';
import 'package:tracelet/domain/traces/trace_point_player.dart';

import 'support/playback_event_log.dart';
import 'support/trace_playback_parity_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Message playback process', () {
    test('realtime trace replay event log is deterministic', () {
      fakeAsync((async) {
        final message = _sampleMessage(async);
        final log1 = _recordTracePointPlayerLog(message, async);
        final log2 = _recordTracePointPlayerLog(message, async);
        expect(log1, log2);
      });
    });

    test(
      'canvas playTrace emits the same replay events as TracePointPlayer',
      () {
        fakeAsync((async) {
          final message = _sampleMessage(async);

          final playerLog = _recordTracePointPlayerLog(message, async);
          final canvasLog = _recordCanvasPlaybackLog(message, async);

          expect(canvasLog, isNotNull);
          expect(
            canvasLog!.sameProcessAs(playerLog),
            isTrue,
            reason: playbackEventLogDiff(playerLog, canvasLog),
          );
        });
      },
    );

    test(
      'played message and realtime playTrace grow canvas identically',
      () {
        fakeAsync((async) {
          final message = _sampleMessage(async);

          final realtimeProcess = _recordCanvasPlaybackProcess(
            async: async,
            message: message,
            start: (harness) => harness.playRealtimeTrace(message),
          );

          final playedProcess = _recordCanvasPlaybackProcess(
            async: async,
            message: message,
            start: (harness) => harness.playReceivedMessage(message),
          );

          expect(
            playbackProcessSnapshotsMatch(realtimeProcess, playedProcess),
            isTrue,
            reason: playbackProcessDiff(realtimeProcess, playedProcess),
          );
        });
      },
    );
  });
}

TraceMessage _sampleMessage(FakeAsync async) {
  final ocean = InMemoryBottleOcean();
  final senderMail = BottleMailService(
    ocean: ocean,
    inbox: MemoryMessageInbox(),
    userId: 'device-sender',
  );

  final sender = TracePlaybackParityHarness.create(
    elapse: async.elapse,
    flushMicrotasks: async.flushMicrotasks,
    profile: TraceProfilePresets.littlePrettify,
    depositMail: senderMail,
  );

  sender.drawSampleTrace();
  sender.waitForSendIdle();

  TraceMessage? message;
  TracePlaybackParityHarness.receiveFromOcean(ocean: ocean).then((received) {
    message = received;
  });
  async.flushMicrotasks();
  expect(message, isNotNull);
  expect(
    message!.points.where((point) => !point.isBreak).length,
    greaterThan(5),
    reason: 'bottle payload should store processed points, not raw finger input',
  );

  sender.dispose();
  return message!;
}

PlaybackEventLog _recordTracePointPlayerLog(
  TraceMessage message,
  FakeAsync async,
) {
  var elapsedMs = 0;
  final host = RecordingPlaybackHost(() => elapsedMs);

  var done = false;
  TracePointPlayer.playByPoints(
    host: host,
    storedPoints: message.points,
    playbackProfile: message.playbackProfile,
    canvasSize: Size(
      message.playbackProfile.captureWidth,
      message.playbackProfile.captureHeight,
    ),
  ).whenComplete(() => done = true);

  while (!done) {
    async.elapse(const Duration(milliseconds: 16));
    elapsedMs += 16;
    async.flushMicrotasks();
  }

  return host.log;
}

PlaybackEventLog? _recordCanvasPlaybackLog(
  TraceMessage message,
  FakeAsync async,
) {
  final harness = TracePlaybackParityHarness.create(
    elapse: async.elapse,
    flushMicrotasks: async.flushMicrotasks,
    profile: TraceProfilePresets.littlePrettify,
  );

  harness.canvas.playbackTelemetryEnabled = true;

  var done = false;
  harness.playReceivedMessage(message).whenComplete(() => done = true);

  while (!done) {
    async.elapse(const Duration(milliseconds: 16));
    async.flushMicrotasks();
  }

  final log = harness.canvas.takePlaybackTelemetryLog();
  harness.dispose();
  return log;
}

List<PlaybackProcessSnapshot> _recordCanvasPlaybackProcess({
  required FakeAsync async,
  required TraceMessage message,
  required Future<void> Function(TracePlaybackParityHarness harness) start,
}) {
  final harness = TracePlaybackParityHarness.create(
    elapse: async.elapse,
    flushMicrotasks: async.flushMicrotasks,
    profile: TraceProfilePresets.littlePrettify,
  );

  final snapshots = <PlaybackProcessSnapshot>[];
  var elapsedMs = 0;

  var done = false;
  start(harness).whenComplete(() => done = true);

  while (!done) {
    snapshots.add(
      PlaybackProcessSnapshot.fromState(harness.canvasState, elapsedMs),
    );
    async.elapse(const Duration(milliseconds: 16));
    elapsedMs += 16;
    async.flushMicrotasks();
  }

  snapshots.add(
    PlaybackProcessSnapshot.fromState(harness.canvasState, elapsedMs),
  );

  harness.dispose();
  return snapshots;
}
