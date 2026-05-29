import 'package:tracelet/domain/models/trace_message.dart';

/// Persists received messages on the device (server deletes on fetch).
abstract interface class MessageInbox {
  Future<List<TraceMessage>> readAll();

  Future<void> writeAll(List<TraceMessage> messages);
}
