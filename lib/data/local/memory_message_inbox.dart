import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/repositories/message_inbox.dart';

/// In-memory inbox for tests and mocks.
class MemoryMessageInbox implements MessageInbox {
  List<TraceMessage> _messages = [];

  @override
  Future<List<TraceMessage>> readAll() async => List.unmodifiable(_messages);

  @override
  Future<void> writeAll(List<TraceMessage> messages) async {
    _messages = List.of(messages);
  }
}
