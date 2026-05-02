import 'package:flutter/material.dart';
import '../models/event.dart';

enum AssistantState {
  idle,
  waitingForProject,
  waitingForTime,
  waitingForTaskName,
  waitingForTaskProject,
  waitingForProjectName,
}

class BotAssistant {
  static bool isMeetingCommand(String input) {
    final text = input.toLowerCase();
    return text.contains('meeting') ||
        text.contains('call') ||
        text.contains('schedule') ||
        text.contains('quick meeting') ||
        text.contains('event now');
  }

  static bool isQuickMeeting(String input) {
    final text = input.toLowerCase();
    return text.contains('quick meeting') ||
        text.contains('meeting now') ||
        text.contains('meeting immediately') ||
        text.contains('call now');
  }

  static bool isTaskCommand(String input) {
    final text = input.toLowerCase();
    return text.contains('create task') ||
        text.contains('add task') ||
        text.contains('new task') ||
        text.contains('make task');
  }

  static bool isProjectCommand(String input) {
    final text = input.toLowerCase();
    return text.contains('create project') ||
        text.contains('new project') ||
        text.contains('add project') ||
        text.contains('start project');
  }

  static bool isDeleteCommand(String input) {
    final text = input.toLowerCase();
    return text.contains('delete') || text.contains('remove');
  }

  static String getInitialResponse(String input, List<String> projectNames) {
    final text = input.toLowerCase();

    if (isQuickMeeting(input) && projectNames.isNotEmpty) {
      return "I'll schedule a quick meeting right now and notify all team members!";
    }

    if (isMeetingCommand(input)) {
      if (projectNames.isEmpty) {
        return "You need to create a project first before scheduling meetings. Say 'create project [name]' to get started.";
      }
      if (projectNames.length == 1) {
        return "I'll schedule a meeting for ${projectNames.first}. What time would you like? (e.g., '2 PM', 'tomorrow 10 AM', 'in 30 minutes')";
      }
      return "Which project is this meeting for?\n\nProjects: ${projectNames.join(', ')}";
    }

    if (isTaskCommand(input)) {
      if (projectNames.isEmpty) {
        return "You need to create a project first. Say 'create project [name]' to get started.";
      }
      final taskName = extractTaskName(input);
      if (taskName != null) {
        if (projectNames.length == 1) {
          return "I'll add '$taskName' to ${projectNames.first}.";
        }
        return "Which project should '$taskName' belong to?\n\nProjects: ${projectNames.join(', ')}";
      }
      return "What task would you like to add?";
    }

    if (isProjectCommand(input)) {
      final projectName = extractProjectName(input);
      if (projectName != null) {
        return "I'll create the project '$projectName'.";
      }
      return "What should the project be called?";
    }

    if (isDeleteCommand(input)) {
      return "What would you like to delete? (project, task, or meeting with name)";
    }

    if (text.contains('hi') || text.contains('hello') || text.contains('hey')) {
      return "Hi! I'm your TeamFlow assistant. I can help you:\n• Create projects, tasks, meetings\n• Schedule quick meetings with instant notifications\n• Delete or edit items\n\nWhat would you like to do?";
    }

    if (text.contains('help')) {
      return "Commands:\n• 'create project [name]'\n• 'add task [name] in [project]'\n• 'meeting in [project] at [time]'\n• 'quick meeting in [project]'\n\nJust tell me what you need!";
    }

    return "I can help you with:\n• Creating projects/tasks\n• Scheduling meetings\n• Quick meetings with instant notifications\n\nWhat would you like to do?";
  }

  static String? extractProjectName(String input) {
    final patterns = [
      RegExp(
        r'(?:create|new|add|start)\s+(?:a\s+)?(?:project\s+)?(?:named?\s+)?(.+)',
      ),
      RegExp(r'project\s+(?:named?\s+)?(.+)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }
    return null;
  }

  static String? extractTaskName(String input) {
    final patterns = [
      RegExp(
        r'(?:create|add|new|make)\s+(?:a\s+)?(?:task\s+)?(?:named?\s+)?(.+?)(?:\s+in\s+|\s+for\s+)',
      ),
      RegExp(r'task\s+(?:named?\s+)?(.+?)(?:\s+in\s+|\s+for\s+)'),
      RegExp(
        r'(?:create|add|new|make)\s+(?:a\s+)?(?:task\s+)?(?:named?\s+)?(.+)',
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && !name.contains('project')) {
          return name;
        }
      }
    }
    return null;
  }

  static String? findProjectInText(String input, List<String> projectNames) {
    for (final name in projectNames) {
      if (input.toLowerCase().contains(name.toLowerCase())) {
        return name;
      }
    }
    return null;
  }

  static String? extractTime(String input) {
    final text = input.toLowerCase();

    if (text.contains('in 30 minutes') || text.contains('30 min')) {
      return '30min';
    }
    if (text.contains('in 1 hour') ||
        text.contains('1 hour') ||
        text.contains('1hr')) {
      return '1hr';
    }
    if (text.contains('in 2 hours') ||
        text.contains('2 hours') ||
        text.contains('2hr')) {
      return '2hr';
    }

    final hourMatch = RegExp(r'(\d+)\s*(?:am|pm|AM|PM)').firstMatch(text);
    if (hourMatch != null) {
      return hourMatch.group(0);
    }

    if (text.contains('morning')) return '9am';
    if (text.contains('afternoon')) return '2pm';
    if (text.contains('evening')) return '5pm';
    if (text.contains('noon')) return '12pm';

    if (text.contains('tomorrow')) return 'tomorrow';
    if (text.contains('next week')) return 'nextweek';

    return null;
  }

  static DateTime calculateMeetingTime(String? timeStr, {DateTime? deadline}) {
    DateTime base = DateTime.now();
    if (timeStr == null) {
      return DateTime(base.year, base.month, base.day, base.hour + 1, 0);
    }

    final lower = timeStr.toLowerCase();

    if (lower == '30min') {
      return DateTime(
        base.year,
        base.month,
        base.day,
        base.hour,
        base.minute + 30,
      );
    }
    if (lower == '1hr') {
      return DateTime(
        base.year,
        base.month,
        base.day,
        base.hour + 1,
        base.minute,
      );
    }
    if (lower == '2hr') {
      return DateTime(
        base.year,
        base.month,
        base.day,
        base.hour + 2,
        base.minute,
      );
    }

    final hourMatch = RegExp(r'(\d+)\s*(am|pm)').firstMatch(lower);
    if (hourMatch != null) {
      int hour = int.parse(hourMatch.group(1)!);
      final period = hourMatch.group(2);
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return DateTime(base.year, base.month, base.day, hour, 0);
    }

    if (lower.contains('tomorrow')) {
      final tomorrow = base.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
    }
    if (lower.contains('nextweek')) {
      final nextWeek = base.add(const Duration(days: 7));
      return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 10, 0);
    }

    if (deadline != null && base.isAfter(deadline)) {
      return deadline;
    }
    return DateTime(base.year, base.month, base.day, base.hour + 1, 0);
  }
}

class AssistantBubble extends StatefulWidget {
  final List<MapEntry<String, DateTime?>> projectsWithDeadline;
  final Function(String projectName)? onCreateProject;
  final Function(String taskTitle, String projectName)? onCreateTask;
  final Function(Event event)? onCreateEvent;
  final Function(String eventTitle)? onDeleteEvent;
  final Function(String taskTitle, String projectName)? onDeleteTask;
  final Function(String projectName)? onDeleteProject;
  final Function(String eventTitle)? onNotifyEventMembers;

  const AssistantBubble({
    super.key,
    required this.projectsWithDeadline,
    this.onCreateProject,
    this.onCreateTask,
    this.onCreateEvent,
    this.onDeleteEvent,
    this.onDeleteTask,
    this.onDeleteProject,
    this.onNotifyEventMembers,
  });

  @override
  State<AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends State<AssistantBubble>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _currentSuggestions = [];
  bool _showTooltip = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  AssistantState _state = AssistantState.idle;
  String? _pendingProject;
  String? _pendingTask;
  String? _selectedProjectFromQuickReply;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<String> get _projectNames =>
      widget.projectsWithDeadline.map((e) => e.key).toList();

  MapEntry<String, DateTime?>? _getProjectWithDeadline(String name) {
    for (final entry in widget.projectsWithDeadline) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        return entry;
      }
    }
    return null;
  }

  void _handleMessage(String input) {
    if (input.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'message': input, 'quickReplies': <Map<String, String>>[]});

      switch (_state) {
        case AssistantState.waitingForProject:
          _handleWaitingForProject(input);
          break;
        case AssistantState.waitingForTime:
          _handleWaitingForTime(input);
          break;
        case AssistantState.waitingForTaskProject:
          _handleWaitingForTaskProject(input);
          break;
        case AssistantState.waitingForTaskName:
          _handleWaitingForTaskName(input);
          break;
        case AssistantState.waitingForProjectName:
          _handleWaitingForProjectName(input);
          break;
        case AssistantState.idle:
          _handleNewCommand(input);
      }
    });
  }

  void _handleNewCommand(String input) {
    final text = input.toLowerCase();

    if (BotAssistant.isQuickMeeting(input) && _projectNames.isNotEmpty) {
      _createQuickMeeting(_projectNames.first);
      return;
    }

    if (BotAssistant.isMeetingCommand(input)) {
      if (_projectNames.isEmpty) {
        _addBotMessage(
          "You need to create a project first. Say 'create project [name]' to get started.",
        );
        _state = AssistantState.idle;
        return;
      }

      final projectName = BotAssistant.findProjectInText(input, _projectNames);
      final timeStr = BotAssistant.extractTime(input);

      if (projectName != null && timeStr != null) {
        _createMeetingWithDetails(projectName, timeStr);
      } else if (projectName != null) {
        _pendingProject = projectName;
        _state = AssistantState.waitingForTime;
        _addBotMessage(
          "What time would you like? (e.g., '2 PM', 'in 30 minutes', 'tomorrow 10 AM')",
        );
      } else if (_projectNames.length == 1) {
        _pendingProject = _projectNames.first;
        _state = AssistantState.waitingForTime;
        _addBotMessage(
          "What time for the meeting? (e.g., '2 PM', 'in 30 minutes', 'tomorrow 10 AM')",
        );
      } else {
        _state = AssistantState.waitingForProject;
        _addBotMessage(
          "Which project is this meeting for?",
          quickReplies: _projectNames.map((p) => {'label': p, 'action': 'project:$p'}).toList(),
        );
      }
      return;
    }

    if (BotAssistant.isTaskCommand(input)) {
      if (_projectNames.isEmpty) {
        _addBotMessage("Create a project first. Say 'create project [name]'.");
        return;
      }

      final taskName = BotAssistant.extractTaskName(input);
      if (taskName != null) {
        final projectName = BotAssistant.findProjectInText(
          input,
          _projectNames,
        );
        if (projectName != null) {
          _createTask(taskName, projectName);
        } else if (_projectNames.length == 1) {
          _createTask(taskName, _projectNames.first);
        } else {
          _pendingTask = taskName;
          _state = AssistantState.waitingForTaskProject;
          _addBotMessage(
            "Which project?",
            quickReplies: _projectNames.map((p) => {'label': p, 'action': 'taskProject:$p'}).toList(),
          );
        }
      } else {
        _state = AssistantState.waitingForTaskName;
        _addBotMessage("What task would you like to add?");
      }
      return;
    }

    if (BotAssistant.isProjectCommand(input)) {
      final name = BotAssistant.extractProjectName(input);
      if (name != null) {
        _createProject(name);
      } else {
        _state = AssistantState.waitingForProjectName;
        _addBotMessage("What should the project be called?");
      }
      return;
    }

    if (text.contains('delete')) {
      _handleDelete(input);
      return;
    }

    if (text.contains('hi') || text.contains('hello') || text.contains('hey')) {
      _addBotMessage(
        "Hi! I can help you:\n• Schedule meetings (with notifications)\n• Create tasks & projects\n• Quick meetings for immediate team alerts\n\nWhat would you like to do?",
      );
    } else if (text.contains('help')) {
      _addBotMessage(
        "Commands:\n• 'create project [name]'\n• 'add task [name] in [project]'\n• 'meeting in [project] at 2pm'\n• 'quick meeting in [project]'\n• 'delete [item] [name]",
      );
    } else {
      _addBotMessage(
        "I didn't understand that. Try:\n• 'schedule meeting'\n• 'add task [name]'\n• 'create project [name]'\n• 'quick meeting'",
      );
    }
  }

  void _handleWaitingForProject(String input) {
    final projectName = BotAssistant.findProjectInText(input, _projectNames);
    if (projectName != null) {
      _pendingProject = projectName;
      _state = AssistantState.waitingForTime;
      _addBotMessage(
        "Got it! What time? (e.g., '2 PM', 'in 30 minutes', 'tomorrow')",
      );
    } else {
      _addBotMessage(
        "I didn't find that project. Please choose:\n\n${_projectNames.map((p) => '• $p').join('\n')}",
      );
    }
  }

  void _handleWaitingForTime(String input) {
    final timeStr = BotAssistant.extractTime(input);
    if (_pendingProject != null) {
      _createMeetingWithDetails(_pendingProject!, timeStr ?? '30min');
      _pendingProject = null;
    }
    _state = AssistantState.idle;
  }

  void _handleWaitingForTaskProject(String input) {
    final projectName = BotAssistant.findProjectInText(input, _projectNames);
    if (projectName != null && _pendingTask != null) {
      _createTask(_pendingTask!, projectName);
      _pendingTask = null;
    } else {
      _addBotMessage(
        "Please choose a valid project:\n\n${_projectNames.map((p) => '• $p').join('\n')}",
      );
    }
    _state = AssistantState.idle;
  }

  void _handleWaitingForTaskName(String input) {
    if (input.trim().isNotEmpty) {
      String? projectName = _selectedProjectFromQuickReply;
      if (projectName == null) {
        projectName = BotAssistant.findProjectInText(input, _projectNames);
      }
      if (projectName == null && _projectNames.isNotEmpty) {
        projectName = _projectNames.first;
      }
      if (projectName != null) {
        _createTask(input.trim(), projectName);
        _selectedProjectFromQuickReply = null;
      } else {
        _addBotMessage("Please specify a project name.");
      }
    } else {
      _addBotMessage("Please provide a task name.");
    }
    _state = AssistantState.idle;
  }

  void _handleWaitingForProjectName(String input) {
    if (input.trim().isNotEmpty) {
      _createProject(input.trim());
    } else {
      _addBotMessage("Please provide a project name.");
    }
    _state = AssistantState.idle;
  }

  void _handleDelete(String input) {
    final text = input.toLowerCase();

    for (final name in _projectNames) {
      if (text.contains(name.toLowerCase()) && text.contains('project')) {
        widget.onDeleteProject?.call(name);
        _addBotMessage("✓ Deleted project '$name'");
        return;
      }
    }

    for (final project in _projectNames) {
      if (text.contains(project.toLowerCase())) {
        _addBotMessage("Which task would you like to delete in '$project'?");
        return;
      }
    }

    if (text.contains('meeting') || text.contains('event')) {
      _addBotMessage(
        "Which meeting would you like to delete? Please provide the meeting name.",
      );
    } else {
      _addBotMessage(
        "I couldn't find what to delete. Please specify:\n• Project name\n• Task name with project\n• Meeting name",
      );
    }
  }

  void _createQuickMeeting(String projectName) {
    final eventTime = DateTime.now().add(const Duration(minutes: 30));

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '$projectName Quick Meeting',
      dateTime: eventTime,
      projectName: projectName,
      createdAt: DateTime.now(),
    );

    widget.onCreateEvent?.call(event);
    widget.onNotifyEventMembers?.call(event.title);
    _addBotMessage(
      "✓ Quick meeting created for $projectName!\n📢 All team members notified!\n⏰ Meeting starts in 30 minutes",
    );
    _state = AssistantState.idle;
  }

  void _createMeetingWithDetails(String projectName, String? timeStr) {
    final projectEntry = _getProjectWithDeadline(projectName);
    final eventTime = BotAssistant.calculateMeetingTime(
      timeStr,
      deadline: projectEntry?.value,
    );

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '$projectName Meeting',
      dateTime: eventTime,
      projectName: projectName,
      createdAt: DateTime.now(),
    );

    widget.onCreateEvent?.call(event);
    _addBotMessage(
      "✓ Meeting scheduled for $projectName\n📅 ${_formatDateTime(eventTime)}\n💡 Don't forget to notify members!",
    );
    _state = AssistantState.idle;
  }

  void _createTask(String taskName, String projectName) {
    widget.onCreateTask?.call(taskName, projectName);
    _addBotMessage("✓ Task '$taskName' added to $projectName");
    _state = AssistantState.idle;
  }

  void _createProject(String name) {
    widget.onCreateProject?.call(name);
    _addBotMessage("✓ Project '$name' created!");
    _state = AssistantState.idle;
  }

  void _addBotMessage(String message, {bool withSuggestions = true, List<Map<String, String>>? quickReplies}) {
    _messages.add({
      'role': 'bot',
      'message': message,
      'quickReplies': quickReplies,
    });
    if (withSuggestions) {
      _addSmartSuggestions('');
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    String time = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    String date = '${dt.day}/${dt.month}';

    if (diff.inDays == 0) {
      return 'Today at $time';
    } else if (diff.inDays == 1) {
      return 'Tomorrow at $time';
    }
    return '$date at $time';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return Positioned(
        bottom: 100,
        right: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_showTooltip)
              Container(
                margin: const EdgeInsets.only(bottom: 12, right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF7C4DFF),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Try: "create project AI App"',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showTooltip = false),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = true;
                        _showTooltip = false;
                        if (_messages.isEmpty) {
                          _messages.add({
                            'role': 'bot',
                            'message': "Hi! I'm your TeamFlow assistant. I can help you:\n• Create projects, tasks, meetings\n• Schedule quick meetings with instant notifications\n• Delete or edit items\n\nWhat would you like to do?",
                          });
                        }
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7C4DFF,
                            ).withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Positioned(
      bottom: 100,
      right: 16,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF7C4DFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'TeamFlow Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isExpanded = false),
                    icon: const Icon(Icons.minimize, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() {
                      _isExpanded = false;
                      _messages.clear();
                      _state = AssistantState.idle;
                    }),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (_currentSuggestions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _currentSuggestions.map((suggestion) {
                    return ActionChip(
                      label: Text(
                        suggestion['label']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _handleSuggestionTap(suggestion['action']!),
                      backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: Color(0xFF7C4DFF)),
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ..._messages.map(
                    (msg) => Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: msg['role'] == 'user'
                            ? const Color(0xFF7C4DFF).withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            msg['role'] == 'user'
                                ? Icons.person
                                : Icons.smart_toy,
                            size: 18,
                            color: msg['role'] == 'user'
                                ? const Color(0xFF7C4DFF)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['message']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: msg['role'] == 'user'
                                        ? const Color(0xFF7C4DFF)
                                        : Colors.black87,
                                  ),
                                ),
                                if (msg['role'] == 'bot' && msg['quickReplies'] != null && (msg['quickReplies'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: (msg['quickReplies'] as List).map<Widget>((reply) {
                                        return GestureDetector(
                                          onTap: () => _handleQuickReplyTap(reply['action']!),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              reply['label']!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF7C4DFF),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_currentSuggestions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _currentSuggestions.map((suggestion) {
                    return ActionChip(
                      label: Text(
                        suggestion['label']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _handleSuggestionTap(suggestion['action']!),
                      backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: Color(0xFF7C4DFF)),
                    );
                  }).toList(),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  _buildQuickActionButton(
                    icon: Icons.add_box_outlined,
                    label: 'Project',
                    onTap: () => _handleQuickAction('create project'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    icon: Icons.task_alt,
                    label: 'Task',
                    onTap: () => _handleQuickAction('add task'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    icon: Icons.calendar_today,
                    label: 'Meeting',
                    onTap: () => _handleQuickAction('schedule meeting'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    icon: Icons.flash_on,
                    label: 'Quick',
                    onTap: () => _handleQuickAction('quick meeting'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        _handleMessage(value);
                        _controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C4DFF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        _handleMessage(_controller.text);
                        _controller.clear();
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
);
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        _controller.clear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF7C4DFF)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(String action) {
    _messages.add({'role': 'user', 'message': action});
    
    switch (action) {
      case 'create project':
        _state = AssistantState.waitingForProjectName;
        _addBotMessage("What should the project be called?");
        _updateSuggestions([
          {'label': 'Cancel', 'action': 'cancel'},
        ]);
        break;
      case 'add task':
        if (_projectNames.isEmpty) {
          _addBotMessage("Create a project first. Say 'create project [name]'.");
          _updateSuggestions([
            {'label': 'Create Project', 'action': 'create project'},
          ]);
        } else {
          _state = AssistantState.waitingForTaskProject;
          _addBotMessage("What task would you like to add?",
            quickReplies: _projectNames.map((p) => {'label': p, 'action': 'taskProject:$p'}).toList(),
          );
          _updateSuggestions([
            {'label': 'Cancel', 'action': 'cancel'},
          ]);
        }
        break;
      case 'schedule meeting':
        if (_projectNames.isEmpty) {
          _addBotMessage("Create a project first to schedule a meeting.");
          _updateSuggestions([
            {'label': 'Create Project', 'action': 'create project'},
          ]);
        } else {
          _state = AssistantState.waitingForProject;
          _addBotMessage("Which project is this meeting for?",
            quickReplies: _projectNames.map((p) => {'label': p, 'action': 'project:$p'}).toList(),
          );
          _updateSuggestions([
            {'label': 'Cancel', 'action': 'cancel'},
          ]);
        }
        break;
      case 'quick meeting':
        if (_projectNames.isEmpty) {
          _addBotMessage("Create a project first to create a quick meeting.");
          _updateSuggestions([
            {'label': 'Create Project', 'action': 'create project'},
          ]);
        } else {
          _createQuickMeeting(_projectNames.first);
        }
        break;
    }
  }

  void _updateSuggestions(List<Map<String, String>> suggestions) {
    setState(() {
      _currentSuggestions.clear();
      _currentSuggestions.addAll(suggestions);
    });
  }

  void _handleSuggestionTap(String action) {
    if (action == 'cancel') {
      _state = AssistantState.idle;
      _addBotMessage("What would you like to do?");
      _updateSuggestions([
        {'label': 'Create Project', 'action': 'create project'},
        {'label': 'Add Task', 'action': 'add task'},
        {'label': 'Schedule Meeting', 'action': 'schedule meeting'},
        {'label': 'Quick Meeting', 'action': 'quick meeting'},
      ]);
    } else {
      _handleQuickAction(action);
    }
  }

  void _addSmartSuggestions(String input) {
    final text = input.toLowerCase();
    List<Map<String, String>> suggestions = [];

    if (text.contains('pro') && _projectNames.any((p) => p.toLowerCase().contains('pro'))) {
      suggestions.add({'label': 'Create Project', 'action': 'create project'});
    }
    if (text.contains('task') || text.contains('add')) {
      suggestions.add({'label': 'Add Task', 'action': 'add task'});
    }
    if (text.contains('meet') || text.contains('schedule')) {
      suggestions.add({'label': 'Schedule Meeting', 'action': 'schedule meeting'});
    }
    if (text.contains('quick') || text.contains('urgent')) {
      suggestions.add({'label': 'Quick Meeting', 'action': 'quick meeting'});
    }

    if (suggestions.isEmpty) {
      suggestions = [
        {'label': 'Create Project', 'action': 'create project'},
        {'label': 'Add Task', 'action': 'add task'},
        {'label': 'Schedule Meeting', 'action': 'schedule meeting'},
      ];
    }

    _updateSuggestions(suggestions);
  }

  void _handleQuickReplyTap(String action) {
    if (action.startsWith('project:')) {
      final projectName = action.substring(8);
      _pendingProject = projectName;
      _state = AssistantState.waitingForTime;
      setState(() {
        _messages.add({'role': 'user', 'message': projectName, 'quickReplies': <Map<String, String>>[]});
        _messages.add({'role': 'bot', 'message': "What time for the meeting?\n\n(e.g., '2 PM', 'in 30 minutes', 'tomorrow 10 AM')", 'quickReplies': <Map<String, String>>[]});
      });
    } else if (action.startsWith('taskProject:')) {
      final projectName = action.substring(12);
      _selectedProjectFromQuickReply = projectName;
      setState(() {
        _messages.add({'role': 'user', 'message': projectName, 'quickReplies': <Map<String, String>>[]});
      });
      _state = AssistantState.waitingForTaskName;
      _addBotMessage("What is the task name?", withSuggestions: false, quickReplies: null);
    }
  }
}
