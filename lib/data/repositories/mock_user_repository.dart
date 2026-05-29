import 'package:tracelet/domain/models/user.dart';
import 'package:tracelet/domain/repositories/user_repository.dart';

/// In-memory mock for development until AWS backend is wired.
class MockUserRepository implements UserRepository {
  MockUserRepository() {
    _friends.addAll(_seedFriends);
    _destinations.addAll(_seedDestinations);
  }

  final List<TraceUser> _friends = [];
  final List<TraceUser> _destinations = [];
  int _destinationIndex = 0;

  static const _seedFriends = [
    TraceUser(id: 'u-alice', displayName: 'Alice'),
    TraceUser(id: 'u-bob', displayName: 'Bob'),
  ];

  static const _seedDestinations = [
    TraceUser(id: 'u-alice', displayName: 'Alice'),
    TraceUser(id: 'u-bob', displayName: 'Bob'),
    TraceUser(id: 'ai-luna', displayName: 'Luna', isAiPersona: true),
    TraceUser(id: 'ai-nova', displayName: 'Nova', isAiPersona: true),
  ];

  @override
  Future<List<TraceUser>> getFriends() async => List.unmodifiable(_friends);

  @override
  Future<List<TraceUser>> getDestinationUsers() async =>
      List.unmodifiable(_destinations);

  @override
  Future<void> deleteFriend(String userId) async {
    _friends.removeWhere((user) => user.id == userId);
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    // Mock: no-op until backend exists.
  }

  @override
  Future<void> acceptFriendRequest(String userId) async {
    final destination = _destinations.firstWhere(
      (user) => user.id == userId,
      orElse: () => TraceUser(id: userId, displayName: 'Friend'),
    );
    if (!_friends.any((user) => user.id == userId)) {
      _friends.add(destination);
    }
  }

  @override
  Future<void> saveNameTrace(String userId, TraceUser nameTrace) async {
    final index = _destinations.indexWhere((user) => user.id == userId);
    if (index >= 0) {
      _destinations[index] = nameTrace;
    }
  }

  TraceUser cycleDestination() {
    if (_destinations.isEmpty) {
      return const TraceUser(id: 'unknown', displayName: 'Unknown');
    }
    _destinationIndex = (_destinationIndex + 1) % _destinations.length;
    return _destinations[_destinationIndex];
  }

  TraceUser get currentDestination =>
      _destinations.isEmpty
          ? const TraceUser(id: 'unknown', displayName: 'Unknown')
          : _destinations[_destinationIndex];
}
