/// Transport for anonymous bottle deposit and pull (SQS FIFO on AWS).
abstract interface class BottleOceanGateway {
  Future<void> deposit({
    required String senderUserId,
    required Map<String, dynamic> payload,
  });

  /// Returns `null` when the ocean is empty.
  Future<Map<String, dynamic>?> pull();
}
