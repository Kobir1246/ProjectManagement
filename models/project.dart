import 'task.dart';

class TeamMember {
  final String id;
  final String name;
  final String initials;
  final String? email;

  TeamMember({
    required this.id,
    required this.name,
    required this.initials,
    this.email,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      name: json['name'] as String,
      initials: json['initials'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'initials': initials, 'email': email};
  }
}

class Project {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? deadline;
  final List<Task> tasks;
  final List<TeamMember> members;

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.deadline,
    this.tasks = const [],
    this.members = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map((t) => Task.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      members:
          (json['members'] as List<dynamic>?)
              ?.map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'members': members.map((m) => m.toJson()).toList(),
    };
  }

  int get completedTasks => tasks.where((t) => t.isCompleted).length;
  int get totalTasks => tasks.length;
  double get completionPercentage =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;

  Project copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? deadline,
    List<Task>? tasks,
    List<TeamMember>? members,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      tasks: tasks ?? this.tasks,
      members: members ?? this.members,
    );
  }
}
