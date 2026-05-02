import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';

class ProjectScreen extends StatefulWidget {
  final Project project;
  final Function(Project) onProjectUpdate;
  final Function(String)? onDeleteProject;
  final int? initialTaskIndex;

  const ProjectScreen({
    super.key,
    required this.project,
    required this.onProjectUpdate,
    this.onDeleteProject,
    this.initialTaskIndex,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late List<Task> _tasks;
  late List<TeamMember> _members;
  late String _projectName;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.project.tasks);
    _members = List.from(widget.project.members);
    _projectName = widget.project.name;
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'completed':
        return _tasks.where((t) => t.isCompleted).toList();
      case 'pending':
        return _tasks.where((t) => !t.isCompleted).toList();
      case 'high':
        return _tasks.where((t) => t.priority == TaskPriority.high).toList();
      case 'medium':
        return _tasks.where((t) => t.priority == TaskPriority.medium).toList();
      case 'low':
        return _tasks.where((t) => t.priority == TaskPriority.low).toList();
      default:
        return _tasks;
    }
  }

  void _updateProject() {
    final updatedProject = widget.project.copyWith(
      name: _projectName,
      tasks: _tasks,
      members: _members,
    );
    widget.onProjectUpdate(updatedProject);
  }

  void _addMember(String name, String email) {
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : email.isNotEmpty
        ? email[0].toUpperCase()
        : '?';

    final member = TeamMember(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isNotEmpty ? name : email.split('@').first,
      initials: initials,
      email: email,
    );

    setState(() {
      _members.add(member);
    });
    _updateProject();
  }

  void _removeMember(TeamMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.name} from this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _members.removeWhere((m) => m.id == member.id);
              });
              
              if (_members.isEmpty) {
                widget.onDeleteProject?.call(widget.project.name);
                Navigator.of(this.context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Project "${widget.project.name}" deleted (no members left)'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } else {
                _updateProject();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('${member.name} removed'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showInviteMemberDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop();
                _addMember(
                  nameController.text.trim(),
                  emailController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Invitation sent!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _addTask(
    String title,
    String? description,
    DateTime? dueDate,
    String? assigneeId,
    TaskPriority priority,
  ) {
    if (title.trim().isEmpty) return;

    setState(() {
      _tasks.add(
        Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title.trim(),
          description: description?.trim(),
          dueDate: dueDate,
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          assigneeId: assigneeId,
          priority: priority,
        ),
      );
    });
    _updateProject();
  }

  void _toggleTask(Task task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(
          isCompleted: !task.isCompleted,
          lastModified: DateTime.now(),
        );
      }
    });
    _updateProject();
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _updateProject();
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    String? selectedAssigneeId;
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPriorityChip(
                            'Low',
                            TaskPriority.low,
                            Colors.green,
                            selectedPriority,
                            (p) => setDialogState(() => selectedPriority = p),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityChip(
                            'Medium',
                            TaskPriority.medium,
                            Colors.orange,
                            selectedPriority,
                            (p) => setDialogState(() => selectedPriority = p),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityChip(
                            'High',
                            TaskPriority.high,
                            Colors.red,
                            selectedPriority,
                            (p) => setDialogState(() => selectedPriority = p),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_members.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedAssigneeId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ..._members.map(
                        (member) => DropdownMenuItem(
                          value: member.id,
                          child: Text(member.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAssigneeId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Set deadline (optional)',
                          style: TextStyle(
                            color: selectedDate != null
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _addTask(
                  titleController.text,
                  descController.text,
                  selectedDate,
                  selectedAssigneeId,
                  selectedPriority,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
    String label,
    TaskPriority priority,
    Color color,
    TaskPriority selected,
    Function(TaskPriority) onTap,
  ) {
    final isSelected = selected == priority;
    return GestureDetector(
      onTap: () => onTap(priority),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final pendingCount = _tasks.length - completedCount;
    final progress = _tasks.isEmpty
        ? 0.0
        : (completedCount / _tasks.length) * 100;
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight * 0.25;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight.clamp(160.0, 220.0),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF7C4DFF),
                      const Color(0xFF7C4DFF).withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                progress == 100 ? 'Completed' : 'In Progress',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Text(
                                _projectName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.project.deadline != null
                                        ? 'Due: ${widget.project.deadline!.day}/${widget.project.deadline!.month}/${widget.project.deadline!.year}'
                                        : 'No deadline set',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          value: progress / 100,
                                          strokeWidth: 4,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.3),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '${progress.round()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamSection(),
                _buildFilterSection(completedCount, pendingCount),
                _buildTasksSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 4),
        child: _AnimatedFAB(onPressed: _showAddTaskDialog),
      ),
    );
  }

  Widget _buildTeamSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Team Members',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_members.length} member${_members.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._members.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  return GestureDetector(
                    onLongPress: () => _removeMember(member),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.primaries[index %
                                          Colors.primaries.length],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    member.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.name,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _showInviteMemberDialog,
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Long press a member to remove',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(int completedCount, int pendingCount) {
    final highPriority = _tasks
        .where((t) => t.priority == TaskPriority.high && !t.isCompleted)
        .length;
    final mediumPriority = _tasks
        .where((t) => t.priority == TaskPriority.medium && !t.isCompleted)
        .length;
    final lowPriority = _tasks
        .where((t) => t.priority == TaskPriority.low && !t.isCompleted)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  count: _tasks.length,
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'In Progress',
                  count: pendingCount,
                  isSelected: _filter == 'pending',
                  onTap: () => setState(() => _filter = 'pending'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Completed',
                  count: completedCount,
                  isSelected: _filter == 'completed',
                  onTap: () => setState(() => _filter = 'completed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPriorityFilterChip(
                  label: 'High',
                  count: highPriority,
                  isSelected: _filter == 'high',
                  color: Colors.red,
                  onTap: () => setState(() => _filter = 'high'),
                ),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(
                  label: 'Medium',
                  count: mediumPriority,
                  isSelected: _filter == 'medium',
                  color: Colors.orange,
                  onTap: () => setState(() => _filter = 'medium'),
                ),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(
                  label: 'Low',
                  count: lowPriority,
                  isSelected: _filter == 'low',
                  color: Colors.green,
                  onTap: () => setState(() => _filter = 'low'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white24
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C4DFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tasks",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_filteredTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to add a task',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._filteredTasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final isCompleted = task.isCompleted;
    final assignee = task.assigneeId != null
        ? _members.where((m) => m.id == task.assigneeId).firstOrNull
        : null;

    final priorityColor = _getPriorityColor(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _BounceCheckbox(
                      isChecked: isCompleted,
                      onTap: () => _toggleTask(task),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? Colors.grey : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showAssigneeDialog(task),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: assignee != null
                                        ? const Color(
                                            0xFF7C4DFF,
                                          ).withValues(alpha: 0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 12,
                                        color: assignee != null
                                            ? const Color(0xFF7C4DFF)
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        assignee?.name ?? 'Unassigned',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: assignee != null
                                              ? const Color(0xFF7C4DFF)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (task.dueDate != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${task.dueDate!.day}/${task.dueDate!.month}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteTask(task);
                        } else if (value == 'edit') {
                          _showEditTaskDialog(task);
                        } else if (value == 'assign') {
                          _showAssigneeDialog(task);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'assign',
                          child: Row(
                            children: [
                              Icon(Icons.person_add, size: 18),
                              SizedBox(width: 8),
                              Text('Assign'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  void _showAssigneeDialog(Task task) {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add team members first to assign tasks'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a team member:'),
            const SizedBox(height: 16),
            ..._members.map(
              (member) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getMemberColor(_members.indexOf(member)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(member.name),
                trailing: task.assigneeId == member.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(dialogContext);
                  _updateTaskAssignee(task, member.id);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_off, color: Colors.grey),
              ),
              title: const Text('Unassigned'),
              trailing: task.assigneeId == null
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(dialogContext);
                _updateTaskAssignee(task, null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getMemberColor(int index) {
    const colors = [
      Color(0xFF7C4DFF),
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFE66D),
      Color(0xFF95E1D3),
      Color(0xFFF38181),
      Color(0xFFAA96DA),
      Color(0xFFFCBAD3),
    ];
    return colors[index % colors.length];
  }

  void _updateTaskAssignee(Task task, String? assigneeId) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(
          assigneeId: assigneeId,
          lastModified: DateTime.now(),
        );
      }
    });
    _updateProject();

    final assignee = assigneeId != null
        ? _members.where((m) => m.id == assigneeId).firstOrNull
        : null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          assignee != null ? 'Assigned to ${assignee.name}' : 'Task unassigned',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');
    DateTime? selectedDate = task.dueDate;
    String? selectedAssigneeId = task.assigneeId;
    TaskPriority selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPriorityChip(
                            'Low',
                            TaskPriority.low,
                            Colors.green,
                            selectedPriority,
                            (p) => setDialogState(() => selectedPriority = p),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityChip(
                            'Medium',
                            TaskPriority.medium,
                            Colors.orange,
                            selectedPriority,
                            (p) => setDialogState(() => selectedPriority = p),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityChip(
                            'High',
                            TaskPriority.high,
                            Colors.red,
                            selectedPriority,
                            (p) => setDialogState(() => selectedPriority = p),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_members.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedAssigneeId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ..._members.map(
                        (member) => DropdownMenuItem(
                          value: member.id,
                          child: Text(member.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAssigneeId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Set deadline (optional)',
                          style: TextStyle(
                            color: selectedDate != null
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  _editTask(
                    task,
                    titleController.text.trim(),
                    descController.text.trim(),
                    selectedDate,
                    selectedAssigneeId,
                    selectedPriority,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editTask(
    Task task,
    String title,
    String? description,
    DateTime? dueDate,
    String? assigneeId,
    TaskPriority priority,
  ) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(
          title: title,
          description: description,
          dueDate: dueDate,
          assigneeId: assigneeId,
          priority: priority,
          lastModified: DateTime.now(),
        );
      }
    });
    _updateProject();
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

class _AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedFAB({required this.onPressed});

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
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
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }
}
