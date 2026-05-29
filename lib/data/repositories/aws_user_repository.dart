import 'package:tracelet/data/api/trace_payload_codec.dart';
import 'package:tracelet/data/api/tracelet_api_client.dart';
import 'package:tracelet/domain/models/user.dart';
import 'package:tracelet/domain/repositories/user_repository.dart';

class AwsUserRepository implements UserRepository {
  AwsUserRepository(this._api);

  final TraceletApiClient _api;

  @override
  Future<List<TraceUser>> getFriends() async {
    final body = await _api.get('/friends');
    return _parseFriends(body['friends']);
  }

  @override
  Future<List<TraceUser>> getDestinationUsers() async => getFriends();

  @override
  Future<void> deleteFriend(String userId) async {
    await _api.delete('/friends', {'friendUserId': userId});
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    await _api.post('/friends', {
      'friendUserId': userId,
      'displayName': userId,
    });
  }

  @override
  Future<void> acceptFriendRequest(String userId) async {
    await sendFriendRequest(userId);
  }

  @override
  Future<void> saveNameTrace(String userId, TraceUser nameTrace) async {
    await _api.put('/friends/name-trace', {
      'friendUserId': userId,
      'displayName': nameTrace.displayName,
      'nameTracePoints': TracePayloadCodec.encodeNameTrace(nameTrace.nameTracePoints),
    });
  }

  List<TraceUser> _parseFriends(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((entry) {
      if (entry is! Map<String, dynamic>) return null;
      return TraceUser(
        id: entry['id']?.toString() ?? '',
        displayName: entry['displayName']?.toString() ?? 'Friend',
        nameTracePoints: TracePayloadCodec.decodeNameTrace(entry['nameTracePoints']),
      );
    }).whereType<TraceUser>().toList();
  }
}
