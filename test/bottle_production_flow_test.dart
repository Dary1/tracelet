import 'dart:async';
import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/data/api/tracelet_api_client.dart';
import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';
import 'package:tracelet/data/local/memory_message_inbox.dart';
import 'package:tracelet/domain/bottle/bottle_send_feedback.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';
import 'package:tracelet/domain/services/bottle_send_coordinator.dart';

import 'support/bottle_production_harness.dart';
import 'support/recording_message_repository.dart';
import 'support/virtual_bottle_handset.dart';

void main() {
  group('BottleProductionHarness (mirrors TraceCanvas wiring)', () {
    test('while drawing, canvas shows visible trace points', () {
      fakeAsync((async) {
        final repo = RecordingMessageRepository();
        final harness = BottleProductionHarness.create(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          repository: repo,
        );

        harness.pointerDownOnCanvas();
        harness.panStart(const Offset(100, 100));
        harness.panUpdate(const Offset(140, 160));

        expect(
          harness.canvas.visiblePointCount,
          greaterThan(0),
          reason: 'Device report: 0 trace visible while drawing',
        );
      });
    });

    test('after stroke without idle wait, deposit is not called yet', () {
      fakeAsync((async) {
        final repo = RecordingMessageRepository();
        final harness = BottleProductionHarness.create(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          repository: repo,
        );

        harness.drawStroke(
          start: const Offset(100, 100),
          moveTo: const Offset(150, 150),
        );

        expect(repo.depositCallCount, 0);
        expect(harness.canvas.visiblePointCount, greaterThan(0));
      });
    });

    test('after stroke and idle wait, deposit is called once', () {
      fakeAsync((async) {
        final repo = RecordingMessageRepository();
        final harness = BottleProductionHarness.create(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          repository: repo,
        );

        harness.drawStroke(
          start: const Offset(100, 100),
          moveTo: const Offset(150, 150),
        );
        harness.waitForSendIdle();

        expect(
          repo.depositCallCount,
          1,
          reason: 'Device report: no SQS message after bottle draw',
        );
        expect(repo.lastDepositedPoints, isNotNull);
      });
    });

    test('device surface: API failure plays error feedback, no throw', () {
      fakeAsync((async) {
        final repo = RecordingMessageRepository(
          throwOnDeposit: TraceletApiException('network down', statusCode: 503),
        );
        final harness = BottleProductionHarness.create(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          repository: repo,
          surface: BottleSendSurface.device,
        );

        harness.drawStroke(moveTo: const Offset(160, 180));
        harness.waitForSendIdle();

        final feedback = harness.feedback as RecordingDeviceFeedback;
        expect(feedback.errorCount, 1);
        expect(feedback.sentCount, 0);
        expect(feedback.lastError, isA<TraceletApiException>());
      });
    });

    test('device surface: backend-not-ready surfaces as error feedback', () {
      fakeAsync((async) {
        final repo = RecordingMessageRepository(
          throwOnDeposit: StateError('Backend not ready'),
        );
        final harness = BottleProductionHarness.create(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          repository: repo,
          surface: BottleSendSurface.device,
        );

        harness.drawStroke(moveTo: const Offset(160, 180));
        harness.waitForSendIdle();

        final feedback = harness.feedback as RecordingDeviceFeedback;
        expect(feedback.errorCount, 1);
        expect(feedback.sentCount, 0);
        expect(feedback.lastError, isA<StateError>());
      });
    });
  });

  group('VirtualBottleHandset (throws on failure)', () {
    test('deposit failure is recorded on virtual feedback', () {
      fakeAsync((async) {
        final handset = VirtualBottleHandset(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          deposit: (_, {required profile, required captureSize}) async {
            throw TraceletApiException('network down', statusCode: 503);
          },
        );

        Object? caught;
        runZoned(
          () {
            handset.drawStroke(moveTo: const Offset(150, 150));
            async.elapse(bottleSendIdleDuration);
            async.flushMicrotasks();
          },
          onError: (error, _) => caught = error,
        );

        expect(caught, isA<TraceletApiException>());
        expect(handset.feedback.lastError, isA<TraceletApiException>());
        expect(handset.sentCount, 0);
      });
    });

    test('successful send increments sentCount', () {
      fakeAsync((async) {
        var deposits = 0;
        final handset = VirtualBottleHandset(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          deposit: (_, {required profile, required captureSize}) async => deposits++,
        );

        handset.drawStroke(moveTo: const Offset(150, 150));
        handset.waitForSendIdle();

        expect(deposits, 1);
        expect(handset.sentCount, 1);
      });
    });
  });

  group('VirtualBottleHandset end-to-end ocean', () {
    test('sender input deposits into shared ocean for receiver', () {
      fakeAsync((async) {
        final ocean = InMemoryBottleOcean();

        final sender = VirtualBottleHandset(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          deposit: (points, {required profile, required captureSize}) =>
              BottleMailService(
            ocean: ocean,
            inbox: MemoryMessageInbox(),
            userId: 'device-a',
          ).sendTrace(
            points,
            profile: profile,
            captureSize: captureSize,
          ),
        );

        sender.drawStroke(moveTo: const Offset(180, 220));
        sender.waitForSendIdle();

        expect(ocean.pendingCount, 1);
        expect(sender.sentCount, 1);
      });
    });
  });
}
