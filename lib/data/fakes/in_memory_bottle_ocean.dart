import 'package:tracelet/domain/gateways/bottle_ocean_gateway.dart';

/// Shared in-memory FIFO ocean for tests and local simulation.
class InMemoryBottleOcean implements BottleOceanGateway {
  final _queue = <Map<String, dynamic>>[];

  @override
  Future<void> deposit({
    required String senderUserId,
    required Map<String, dynamic> payload,
  }) async {
    _queue.add({
      'senderUserId': senderUserId,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<Map<String, dynamic>?> pull() async {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  int get pendingCount => _queue.length;
}
