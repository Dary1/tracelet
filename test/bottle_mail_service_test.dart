import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';
import 'support/virtual_device.dart';

TracePoint _point(double x, double y, {int ms = 0}) {
  return TracePoint(
    position: Offset(x, y),
    timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
  );
}

List<TracePoint> _sampleTrace() => [
      _point(80, 240, ms: 0),
      _point(160, 400, ms: 50),
      _point(240, 560, ms: 100),
    ];

void main() {
  group('VirtualDevice bottle mail', () {
    test('device A sends, device B receives without GUI', () async {
      final pair = VirtualDevicePair.create(
        senderId: 'device-a',
        receiverId: 'device-b',
      );

      await pair.sender.sendBottleMessage(_sampleTrace());

      final message = await pair.receiver.receiveBottleMessage();

      expect(message.sender.id, 'device-a');
      expect(message.points, hasLength(3));
      expect(message.points[0].position.dx, closeTo(0.2, 0.01));
      expect(message.points[0].position.dy, closeTo(0.3, 0.01));
      expect(message.playbackProfile.isNormalized, isTrue);
    });

    test('receive fails when ocean is empty', () async {
      final device = VirtualDevice.create(
        deviceId: 'lonely-device',
        displayName: 'Lonely',
        ocean: InMemoryBottleOcean(),
      );

      expect(
        () => device.receiveBottleMessage(),
        throwsA(isA<NoBottleAvailableException>()),
      );
    });

    test('send fails for empty trace', () async {
      final pair = VirtualDevicePair.create();

      expect(
        () => pair.sender.sendBottleMessage(const []),
        throwsA(isA<BottleMailException>()),
      );
    });

    test('FIFO: first deposited bottle is pulled first', () async {
      final ocean = InMemoryBottleOcean();
      final deviceA = VirtualDevice.create(
        deviceId: 'a',
        displayName: 'A',
        ocean: ocean,
      );
      final deviceB = VirtualDevice.create(
        deviceId: 'b',
        displayName: 'B',
        ocean: ocean,
      );
      final deviceC = VirtualDevice.create(
        deviceId: 'c',
        displayName: 'C',
        ocean: ocean,
      );

      await deviceA.sendBottleMessage([_point(1, 1)]);
      await deviceB.sendBottleMessage([_point(2, 2)]);

      final first = await deviceC.receiveBottleMessage();
      final second = await deviceC.receiveBottleMessage();

      expect(first.sender.id, 'a');
      expect(second.sender.id, 'b');
      expect(ocean.pendingCount, 0);
    });

    test('received message is stored on receiver inbox only', () async {
      final pair = VirtualDevicePair.create();

      await pair.sender.sendBottleMessage(_sampleTrace());
      await pair.receiver.receiveBottleMessage();

      expect(await pair.sender.receivedMessages(), isEmpty);
      expect(await pair.receiver.receivedMessages(), hasLength(1));
    });

    test('skips own bottle and receives the next one', () async {
      final ocean = InMemoryBottleOcean();
      final self = VirtualDevice.create(
        deviceId: 'same-user',
        displayName: 'Self',
        ocean: ocean,
      );
      final other = VirtualDevice.create(
        deviceId: 'other-user',
        displayName: 'Other',
        ocean: ocean,
      );

      await self.sendBottleMessage([_point(9, 9)]);
      await other.sendBottleMessage(_sampleTrace());

      final message = await self.receiveBottleMessage();

      expect(message.sender.id, 'other-user');
      expect(message.points, hasLength(3));
      expect(message.points[0].position.dx, closeTo(0.2, 0.01));
    });

    test('returns no bottle when ocean only contains own messages', () async {
      final ocean = InMemoryBottleOcean();
      final device = VirtualDevice.create(
        deviceId: 'solo-user',
        displayName: 'Solo',
        ocean: ocean,
      );

      await device.sendBottleMessage(_sampleTrace());

      await expectLater(
        device.receiveBottleMessage(),
        throwsA(isA<NoBottleAvailableException>()),
      );
      expect(ocean.pendingCount, 1);
    });

    test(
      'self receive leaves bottle in ocean for another device',
      () async {
        final ocean = InMemoryBottleOcean();
        final deviceA = VirtualDevice.create(
          deviceId: 'device-a',
          displayName: 'A',
          ocean: ocean,
        );
        final deviceB = VirtualDevice.create(
          deviceId: 'device-b',
          displayName: 'B',
          ocean: ocean,
        );

        await deviceA.sendBottleMessage(_sampleTrace());
        expect(ocean.pendingCount, 1);

        await expectLater(
          deviceA.receiveBottleMessage(),
          throwsA(isA<NoBottleAvailableException>()),
        );
        expect(
          ocean.pendingCount,
          1,
          reason: 'skipping own bottle must not delete it from the ocean',
        );

        final message = await deviceB.receiveBottleMessage();

        expect(message.sender.id, 'device-a');
        expect(ocean.pendingCount, 0);
      },
    );
  });
}
