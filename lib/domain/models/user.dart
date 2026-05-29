/// A Tracelet user or AI persona that can send/receive messages.
class TraceUser {
  const TraceUser({
    required this.id,
    required this.displayName,
    this.isAiPersona = false,
    this.nameTracePoints = const [],
  });

  final String id;
  final String displayName;
  final bool isAiPersona;
  final List<({double dx, double dy, int msSinceStart})> nameTracePoints;

  TraceUser copyWith({
    String? id,
    String? displayName,
    bool? isAiPersona,
    List<({double dx, double dy, int msSinceStart})>? nameTracePoints,
  }) {
    return TraceUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isAiPersona: isAiPersona ?? this.isAiPersona,
      nameTracePoints: nameTracePoints ?? this.nameTracePoints,
    );
  }
}
