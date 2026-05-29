import 'package:tracelet/domain/models/user.dart';

/// Contract for user/friend management (AWS DynamoDB later).
abstract interface class UserRepository {
  Future<List<TraceUser>> getFriends();

  Future<List<TraceUser>> getDestinationUsers();

  Future<void> deleteFriend(String userId);

  Future<void> sendFriendRequest(String userId);

  Future<void> acceptFriendRequest(String userId);

  Future<void> saveNameTrace(String userId, TraceUser nameTrace);
}
