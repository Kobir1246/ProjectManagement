import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/event.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../widgets/assistant_bubble.dart';
import '../widgets/team_flow_logo.dart';
import 'events_screen.dart';
import 'projects_list_screen.dart';
import 'profile_screen.dart';
import 'project_screen.dart';

class PendingTaskItem {
  final Task task;
  final Project project;

  PendingTaskItem({required this.task, required this.project});
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Project> _projects = [];
  final List<Event> _events = [];
  bool _isLoading = true;
  bool _showOnboarding = false;
  int _onboardingStep = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedProjects = await storageService.loadProjects();
    final loadedEvents = await storageService.loadEvents();
    final hasOnboarding = await storageService.hasShownOnboarding();
    setState(() {
      _projects.clear();
      _projects.addAll(loadedProjects);
      _events.clear();
      _events.addAll(loadedEvents);
      _isLoading = false;
      _showOnboarding = !hasOnboarding;
    });
  }

  Future<void> _saveData() async {
    await storageService.saveProjects(_projects);
    await storageService.saveEvents(_events);
  }

  int get _totalTasks {
    int count = 0;
    for (var project in _projects) {
      count += project.tasks.length;
    }
    return count;
  }

  int get _completedTasks {
    int count = 0;
    for (var project in _projects) {
      for (var task in project.tasks) {
        if (task.isCompleted) count++;
      }
    }
    return count;
  }

  int get _pendingTasks => _totalTasks - _completedTasks;

  double get _overallProgress {
    if (_totalTasks == 0) return 0;
    return (_completedTasks / _totalTasks) * 100;
  }

  List<PendingTaskItem> get _pendingTasksList {
    List<PendingTaskItem> pending = [];
    for (var project in _projects) {
      for (var task in project.tasks) {
        if (!task.isCompleted) {
          pending.add(PendingTaskItem(task: task, project: project));
        }
      }
    }
    pending.sort((a, b) {
      final aTime = a.task.dueDate ?? a.task.createdAt;
      final bTime = b.task.dueDate ?? b.task.createdAt;
      return aTime.compareTo(bTime);
    });
    return pending.take(5).toList();
  }

  List<Project> get _sortedProjects {
    final sorted = List<Project>.from(_projects);
    sorted.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });
    return sorted;
  }

  Project? _addProject(String name, DateTime? deadline) {
    if (name.trim().isEmpty) return null;

    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
      deadline: deadline,
      members: [TeamMember(id: '1', name: 'You', initials: 'Y')],
    );

    setState(() {
      _projects.add(project);
    });
    _saveData();

    if (deadline != null) {
      notificationService.scheduleDeadlineReminder(
        project.id,
        project.name,
        deadline,
      );
    }

    return project;
  }

  void _addEvent(Event event) {
    setState(() {
      _events.insert(0, event);
    });
    _saveData();
    notificationService.scheduleEventReminder(event);
  }

  void _notifyEventMembers(String eventId) {
    final event = _events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );
    setState(() {
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _events[index] = _events[index].copyWith(notified: true);
      }
    });
    _saveData();
    notificationService.showInstantNotification(
      'Meeting Reminder',
      '${event.title} starts in 30 minutes!',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Members notified!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _deleteEvent(String eventTitle) {
    setState(() {
      _events.removeWhere(
        (e) => e.title.toLowerCase() == eventTitle.toLowerCase(),
      );
    });
    _saveData();
  }

  void _deleteTask(String taskTitle, String projectName) {
    final projectIndex = _projects.indexWhere(
      (p) => p.name.toLowerCase() == projectName.toLowerCase(),
    );
    if (projectIndex != -1) {
      final project = _projects[projectIndex];
      final updatedTasks = project.tasks
          .where((t) => t.title.toLowerCase() != taskTitle.toLowerCase())
          .toList();
      final updatedProject = project.copyWith(tasks: updatedTasks);
      setState(() {
        _projects[projectIndex] = updatedProject;
      });
      _saveData();
    }
  }

  void _deleteProject(String projectName) {
    setState(() {
      _projects.removeWhere(
        (p) => p.name.toLowerCase() == projectName.toLowerCase(),
      );
    });
    _saveData();
  }

  void _navigateToProject(Project project, {int? taskIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectScreen(
          project: project,
          initialTaskIndex: taskIndex,
          onProjectUpdate: (updatedProject) {
            setState(() {
              final index = _projects.indexWhere((p) => p.id == project.id);
              if (index != -1) {
                _projects[index] = updatedProject;
              }
            });
          },
          onDeleteProject: (name) => _deleteProject(name),
        ),
      ),
    ).then((_) {
      setState(() {
        _currentIndex = 3;
      });
    });
  }

  void _showAddProjectDialog() {
    final controller = TextEditingController();
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Project name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDeadline = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          selectedDeadline != null
                              ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                              : 'Set deadline (optional)',
                          style: TextStyle(
                            color: selectedDeadline != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final project = _addProject(controller.text, selectedDeadline);
                if (project != null) {
                  Navigator.of(dialogContext).pop();
                  _navigateToProject(project);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    if (_projects.length > 1) {
      _showProjectSelectorForEvent();
    } else if (_projects.isNotEmpty) {
      _showEventDetailsDialog(_projects.first.name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Create a project first to schedule events'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showProjectSelectorForEvent() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a project for this event:'),
              const SizedBox(height: 16),
              ..._projects.map(
                (project) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder, color: Colors.blue.shade600),
                  ),
                  title: Text(project.name),
                  subtitle: project.deadline != null
                      ? Text(
                          'Due: ${project.deadline!.day}/${project.deadline!.month}/${project.deadline!.year}',
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _showEventDetailsDialog(project.name);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsDialog(String projectName) {
    final project = _projects.firstWhere((p) => p.name == projectName);
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    DateTime minDate = DateTime.now();
    if (project.deadline != null) {
      minDate = DateTime.now().isBefore(project.deadline!)
          ? DateTime.now()
          : project.deadline!;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('New Event - $projectName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Event title',
                    hintText: 'e.g., Team Meeting',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: minDate,
                      lastDate:
                          project.deadline ??
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (project.deadline != null) ...[
                          const Spacer(),
                          Text(
                            'Max: ${project.deadline!.day}/${project.deadline!.month}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;

                final eventDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                if (project.deadline != null &&
                    eventDateTime.isAfter(project.deadline!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Event cannot be after project deadline (${project.deadline!.day}/${project.deadline!.month})',
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  return;
                }

                final event = Event(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  dateTime: eventDateTime,
                  projectName: projectName,
                  createdAt: DateTime.now(),
                );

                _addEvent(event);
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Event created!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthService>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSearchOverlay() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SearchScreen(
          projects: _projects,
          events: _events,
          onProjectTap: (project) {
            Navigator.of(context).pop();
            _navigateToProject(project);
          },
          onEventTap: (event) {
            Navigator.of(context).pop();
            setState(() {
              _currentIndex = 1;
            });
          },
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) return Colors.red;
    if (percentage < 70) return Colors.orange;
    return Colors.green;
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickStats(),
          const SizedBox(height: 16),
          _buildProjectsOverview(),
          const SizedBox(height: 16),
          _buildDeadlinesSection(),
          const SizedBox(height: 16),
          _buildPendingSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _overallProgress / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(_overallProgress),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_overallProgress.round()}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(_overallProgress),
                      ),
                    ),
                    Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  Icons.folder_rounded,
                  'Projects',
                  _projects.length.toString(),
                  const Color(0xFF7C4DFF),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  Icons.task_alt_rounded,
                  'Completed',
                  _completedTasks.toString(),
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  Icons.pending_actions,
                  'Pending',
                  _pendingTasks.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProjectsOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Projects Progress',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_overallProgress.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_projects.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No projects yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _projects.take(3).map((project) {
                final progress = project.completionPercentage;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${progress.round()}%',
                            style: TextStyle(
                              color: _getProgressColor(progress),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(progress),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesSection() {
    final upcomingDeadlines =
        _projects
            .where(
              (p) =>
                  p.deadline != null &&
                  p.deadline!.isAfter(DateTime.now()) &&
                  p.completionPercentage < 100,
            )
            .toList()
          ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    if (upcomingDeadlines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 14),
              const Text(
                'Upcoming Deadlines',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...upcomingDeadlines.take(3).map((project) {
            final daysLeft = project.deadline!
                .difference(DateTime.now())
                .inDays;
            final isUrgent = daysLeft <= 3;

            return GestureDetector(
              onTap: () => _navigateToProject(project),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? Colors.red.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          daysLeft.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUrgent ? Colors.red : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            daysLeft == 0
                                ? 'Due today'
                                : daysLeft == 1
                                ? 'Due tomorrow'
                                : 'days left',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    final pendingTasks = _pendingTasksList;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Pending Tasks',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pendingTasks.length}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pendingTasks.isEmpty)
            _EmptyState(
              icon: _projects.isEmpty
                  ? Icons.folder_outlined
                  : Icons.check_circle_outline,
              title: _projects.isEmpty ? 'No projects yet' : 'All caught up!',
              subtitle: _projects.isEmpty
                  ? 'Create your first project to get started'
                  : 'No pending tasks — you\'re doing great!',
              emoji: _projects.isEmpty ? '🚀' : '🎉',
            )
          else
            ...pendingTasks.map((item) => _buildPendingTaskItem(item)),
        ],
      ),
    );
  }

  String _getSmartDueLabel(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    if (diff <= 3) return 'Almost Done';
    return '${diff}d left';
  }

  Widget _buildPendingTaskItem(PendingTaskItem item) {
    final dueDate = item.task.dueDate;
    final dueLabel = dueDate != null ? _getSmartDueLabel(dueDate) : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());
    final isUrgent = dueLabel == 'Due Today' || dueLabel == 'Almost Done';

    Color labelColor = Colors.grey.shade600;
    if (isOverdue)
      labelColor = Colors.red;
    else if (dueLabel == 'Due Today')
      labelColor = Colors.orange;
    else if (dueLabel == 'Almost Done')
      labelColor = Colors.amber.shade700;

    return GestureDetector(
      onTap: () => _navigateToProject(item.project),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue
              ? Colors.red.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue
              ? Border.all(color: Colors.red.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red
                    : (isUrgent ? Colors.orange : Colors.green),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.project.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (dueLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dueLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ),
            if (item.task.dueDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.task.dueDate!.day}/${item.task.dueDate!.month}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      _buildHomeContent(),
      EventsScreen(
        events: _events,
        onEventCreated: _addEvent,
        onNotifyMembers: _notifyEventMembers,
        onDeleteEvent: _deleteEvent,
      ),
      const SizedBox(),
      ProjectsListScreen(
        projects: _sortedProjects,
        onProjectTap: (project) => _navigateToProject(project),
        onDeleteProject: (name) => _deleteProject(name),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const TeamFlowLogo(size: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TeamFlow',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Manage your team efficiently',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSearchOverlay,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          if (_showOnboarding) _buildOnboardingOverlay(),
          AssistantBubble(
            projectsWithDeadline: _projects
                .map((p) => MapEntry(p.name, p.deadline))
                .toList(),
            onCreateProject: (name) {
              final project = _addProject(name, null);
              if (project != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Project "$name" created!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            onCreateTask: (title, projectName) {
              final projectIndex = _projects.indexWhere(
                (p) => p.name.toLowerCase() == projectName.toLowerCase(),
              );
              if (projectIndex != -1) {
                final project = _projects[projectIndex];
                final task = Task(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  createdAt: DateTime.now(),
                  lastModified: DateTime.now(),
                );
                final updatedProject = project.copyWith(
                  tasks: [...project.tasks, task],
                );
                setState(() {
                  _projects[projectIndex] = updatedProject;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "$title" added to $projectName'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            onCreateEvent: (event) {
              _addEvent(event);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event "${event.title}" created!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            onDeleteEvent: (eventTitle) {
              _deleteEvent(eventTitle);
            },
            onDeleteTask: (taskTitle, projectName) {
              _deleteTask(taskTitle, projectName);
            },
            onDeleteProject: (projectName) {
              _deleteProject(projectName);
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF7C4DFF),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Events',
            ),
            BottomNavigationBarItem(icon: SizedBox(width: 24), label: ''),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_drive_file_outlined),
              activeIcon: Icon(Icons.insert_drive_file),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _ExpandableFAB(
        onCreateProject: _showAddProjectDialog,
        onCreateMeeting: _showAddEventDialog,
        hasProjectsWithMembers: _projects.any((p) => p.members.length >= 2),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildOnboardingOverlay() {
    final tips = [
      {'title': 'Welcome to TeamFlow!', 'message': 'Your AI assistant can help you create projects, tasks, and meetings.'},
      {'title': 'Quick Actions', 'message': 'Use the + button to create projects or schedule meetings.'},
      {'title': 'AI Assistant', 'message': 'Tap the bot icon to create items using voice or text commands.'},
      {'title': 'Search', 'message': 'Tap the search icon to find projects, tasks, and events quickly.'},
    ];

    return GestureDetector(
      onTap: () {
        if (_onboardingStep < tips.length - 1) {
          setState(() {
            _onboardingStep++;
          });
        } else {
          setState(() {
            _showOnboarding = false;
          });
          storageService.setOnboardingShown();
        }
      },
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tips_and_updates,
                  size: 48,
                  color: const Color(0xFF7C4DFF),
                ),
                const SizedBox(height: 16),
                Text(
                  tips[_onboardingStep]['title']!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  tips[_onboardingStep]['message']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(tips.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _onboardingStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _onboardingStep
                            ? const Color(0xFF7C4DFF)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to continue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchScreen extends StatefulWidget {
  final List<Project> projects;
  final List<Event> events;
  final Function(Project) onProjectTap;
  final Function(Event) onEventTap;

  const _SearchScreen({
    required this.projects,
    required this.events,
    required this.onProjectTap,
    required this.onEventTap,
  });

  @override
  State<_SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<_SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'all';

  List<Project> get _filteredProjects {
    if (_query.isEmpty) return [];
    return widget.projects
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  List<Task> get _filteredTasks {
    if (_query.isEmpty) return [];
    final tasks = <Task>[];
    for (final project in widget.projects) {
      for (final task in project.tasks) {
        if (task.title.toLowerCase().contains(_query.toLowerCase())) {
          tasks.add(task);
        }
      }
    }
    return tasks;
  }

  List<Event> get _filteredEvents {
    if (_query.isEmpty) return [];
    return widget.events
        .where((e) => e.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search projects, tasks, events...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Projects', 'projects'),
                const SizedBox(width: 8),
                _buildFilterChip('Tasks', 'tasks'),
                const SizedBox(width: 8),
                _buildFilterChip('Events', 'events'),
              ],
            ),
          ),
          Expanded(
            child: _query.isEmpty ? _buildEmptyState() : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C4DFF) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Search for projects, tasks, or events',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final projects = _filter == 'all' || _filter == 'projects'
        ? _filteredProjects
        : [];
    final tasks = _filter == 'all' || _filter == 'tasks' ? _filteredTasks : [];
    final events = _filter == 'all' || _filter == 'events'
        ? _filteredEvents
        : [];

    final totalResults = projects.length + tasks.length + events.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_query"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (projects.isNotEmpty) ...[
          _buildSectionHeader('Projects', projects.length),
          ...projects.map((p) => _buildProjectItem(p)),
        ],
        if (tasks.isNotEmpty) ...[
          _buildSectionHeader('Tasks', tasks.length),
          ...tasks.map((t) => _buildTaskItem(t)),
        ],
        if (events.isNotEmpty) ...[
          _buildSectionHeader('Events', events.length),
          ...events.map((e) => _buildEventItem(e)),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFF7C4DFF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder, color: Color(0xFF7C4DFF)),
        ),
        title: Text(project.name),
        subtitle: Text('${project.tasks.length} tasks'),
        trailing: Text(
          '${project.completionPercentage.round()}%',
          style: TextStyle(
            color: _getProgressColor(project.completionPercentage),
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => widget.onProjectTap(project),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final project = widget.projects.firstWhere(
      (p) => p.tasks.any((t) => t.id == task.id),
      orElse: () => widget.projects.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: task.isCompleted
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(project.name),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () => widget.onProjectTap(project),
      ),
    );
  }

  Widget _buildEventItem(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event, color: Colors.blue),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () => widget.onEventTap(event),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) return Colors.red;
    if (percentage < 70) return Colors.orange;
    return Colors.green;
  }
}

class _BounceCheckbox extends StatefulWidget {
  final bool isChecked;
  final VoidCallback onTap;

  const _BounceCheckbox({required this.isChecked, required this.onTap});

  @override
  State<_BounceCheckbox> createState() => _BounceCheckboxState();
}

class _BounceCheckboxState extends State<_BounceCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_BounceCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked && widget.isChecked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isChecked ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
                color: widget.isChecked ? Colors.green : Colors.transparent,
              ),
              child: widget.isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String emoji;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableFAB extends StatefulWidget {
  final VoidCallback onCreateProject;
  final VoidCallback onCreateMeeting;
  final bool hasProjectsWithMembers;

  const _ExpandableFAB({
    required this.onCreateProject,
    required this.onCreateMeeting,
    required this.hasProjectsWithMembers,
  });

  @override
  State<_ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<_ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create New',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.folder_outlined,
              title: 'Project',
              subtitle: 'Create a new project',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                widget.onCreateProject();
              },
            ),
            if (widget.hasProjectsWithMembers) ...[
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Icons.event,
                title: 'Add Event',
                subtitle: 'Schedule a new event',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  widget.onCreateMeeting();
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _showAddOptions();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          );
        },
      ),
    );
  }
}
