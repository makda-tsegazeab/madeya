class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.targetScope,
    this.targetRole,
    this.targetStationId,
  });

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? targetScope;
  final String? targetRole;
  final int? targetStationId;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      targetScope: json['targetScope'] as String?,
      targetRole: json['targetRole'] as String?,
      targetStationId: json['targetStationId'] as int?,
    );
  }
}
