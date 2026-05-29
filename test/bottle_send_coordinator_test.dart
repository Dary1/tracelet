import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/services/bottle_send_coordinator.dart';

void main() {
  group('BottleSendCoordinator', () {
    test('sends after idle with no new points', () {
      fakeAsync((async) {
        var sent = false;
        var discarded = false;

        final coordinator = BottleSendCoordinator(
          onCommitSend: () async => sent = true,
          onDiscard: () async => discarded = true,
        );

        coordinator.notifyPointAdded();
        coordinator.notifyPointerReleased();

        expect(sent, isFalse);
        async.elapse(bottleSendIdleDuration);
        async.flushMicrotasks();

        expect(sent, isTrue);
        expect(discarded, isFalse);
        coordinator.dispose();
      });
    });

    test('resets idle timer when new points arrive', () {
      fakeAsync((async) {
        var sent = false;

        final coordinator = BottleSendCoordinator(
          onCommitSend: () async => sent = true,
          onDiscard: () async {},
        );

        coordinator.notifyPointAdded();
        coordinator.notifyPointerReleased();
        async.elapse(const Duration(milliseconds: 700));
        coordinator.notifyPointAdded();

        async.elapse(const Duration(milliseconds: 700));
        expect(sent, isFalse);

        async.elapse(const Duration(milliseconds: 800));
        async.flushMicrotasks();
        expect(sent, isTrue);
        coordinator.dispose();
      });
    });

    test('multi-touch blocks drawing and discards after idle', () {
      fakeAsync((async) {
        var sent = false;
        var discarded = false;

        final coordinator = BottleSendCoordinator(
          onCommitSend: () async => sent = true,
          onDiscard: () async => discarded = true,
        );

        coordinator.notifyPointAdded();
        coordinator.notifyMultiTouch();

        expect(coordinator.isDrawingBlocked, isTrue);
        coordinator.notifyPointAdded();
        async.elapse(bottleSendIdleDuration);
        async.flushMicrotasks();

        expect(sent, isFalse);
        expect(discarded, isTrue);
        expect(coordinator.isDrawingBlocked, isFalse);
        coordinator.dispose();
      });
    });

    test('multi-touch cancels pending send', () {
      fakeAsync((async) {
        var sent = false;
        var discarded = false;

        final coordinator = BottleSendCoordinator(
          onCommitSend: () async => sent = true,
          onDiscard: () async => discarded = true,
        );

        coordinator.notifyPointerReleased();
        async.elapse(const Duration(milliseconds: 400));
        coordinator.notifyMultiTouch();
        async.elapse(bottleSendIdleDuration);
        async.flushMicrotasks();

        expect(sent, isFalse);
        expect(discarded, isTrue);
        coordinator.dispose();
      });
    });
  });
}
