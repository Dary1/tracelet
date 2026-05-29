import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';
import 'package:tracelet/data/local/memory_message_inbox.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';

import 'support/virtual_bottle_handset.dart';

void main() {
  group('VirtualBottleHandset input emulation', () {
    test('draw, lift, wait for send idle deposits to ocean', () {
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

        sender.drawStroke(
          start: const Offset(100, 100),
          moveTo: const Offset(150, 150),
        );
        expect(ocean.pendingCount, 0);

        sender.waitForSendIdle();
        expect(ocean.pendingCount, 1);
        expect(sender.sentCount, 1);
      });
    });

    test('continued drawing resets idle timer before send', () {
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

        sender.drawStroke(start: const Offset(100, 100));
        async.elapse(const Duration(milliseconds: 700));

        sender.drawStroke(start: const Offset(200, 200));
        async.elapse(const Duration(milliseconds: 700));
        expect(ocean.pendingCount, 0);

        sender.waitForSendIdle();
        expect(ocean.pendingCount, 1);
      });
    });

    test('second finger cancels send and discards after idle', () {
      fakeAsync((async) {
        final sender = VirtualBottleHandset(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          deposit: (_, {required profile, required captureSize}) async {},
        );

        sender.fingerDown();
        sender.fingerMove(const Offset(140, 160));
        sender.secondFingerDown();

        expect(sender.session.isDrawingBlocked, isTrue);
        sender.waitForDiscardIdle();

        expect(sender.sentCount, 0);
        expect(sender.discardCount, 1);
      });
    });

    test('multi-touch during pending send window discards instead of sending', () {
      fakeAsync((async) {
        var deposits = 0;
        final sender = VirtualBottleHandset(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          deposit: (_, {required profile, required captureSize}) async => deposits++,
        );

        sender.fingerDown();
        sender.fingerMove(const Offset(130, 170));
        async.elapse(const Duration(milliseconds: 400));
        sender.secondFingerDown();
        sender.waitForDiscardIdle();

        expect(deposits, 0);
        expect(sender.discardCount, 1);
      });
    });
  });
}
