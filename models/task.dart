enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? lastModified;
  final String? assigneeId;
  final TaskPriority priority;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.lastModified,
    this.assigneeId,
    this.priority = TaskPriority.medium,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      assigneeId: json['assigneeId'] as String?,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'assigneeId': assigneeId,
      'priority': priority.name,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? lastModified,
    String? assigneeId,
    TaskPriority? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      assigneeId: assigneeId ?? this.assigneeId,
      priority: priority ?? this.priority,
    );
  }
}
