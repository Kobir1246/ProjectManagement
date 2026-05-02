class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? projectId;
  final String? projectName;
  final List<String> memberIds;
  final bool notified;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    this.projectId,
    this.projectName,
    this.memberIds = const [],
    this.notified = false,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
      memberIds:
          (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      notified: json['notified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'projectId': projectId,
      'projectName': projectName,
      'memberIds': memberIds,
      'notified': notified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? projectId,
    String? projectName,
    List<String>? memberIds,
    bool? notified,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      memberIds: memberIds ?? this.memberIds,
      notified: notified ?? this.notified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
