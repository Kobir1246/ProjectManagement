import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../widgets/team_flow_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Project> _projects = [];

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

  List<Task> get _recentTasks {
    List<Task> allTasks = [];
    for (var project in _projects) {
      allTasks.addAll(project.tasks);
    }
    allTasks.sort((a, b) {
      final aTime = a.lastModified ?? a.createdAt;
      final bTime = b.lastModified ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return allTasks.take(5).toList();
  }

  List<Task> get _pendingTasksList {
    List<Task> pending = [];
    for (var project in _projects) {
      for (var task in project.tasks) {
        if (!task.isCompleted) {
          pending.add(task);
        }
      }
    }
    pending.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      return bTime.compareTo(aTime);
    });
    return pending.take(5).toList();
  }

  void _addProject(String name) {
    if (name.trim().isEmpty) return;

    setState(() {
      _projects.add(
        Project(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.trim(),
          createdAt: DateTime.now(),
          members: [TeamMember(id: '1', name: 'You', initials: 'Y')],
        ),
      );
    });
  }

  void _showAddProjectDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Project name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _addProject(value);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _addProject(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
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

  Color _getProgressColor(double percentage) {
    if (percentage < 30) return Colors.red;
    if (percentage < 70) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 16),
            _buildPendingSection(),
            const SizedBox(height: 16),
            _buildRecentSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final progressColor = _getProgressColor(_overallProgress);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _overallProgress / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_overallProgress.round()}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildProgressItem(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  label: 'Completed',
                  value: _completedTasks.toString(),
                ),
                const SizedBox(height: 8),
                _buildProgressItem(
                  icon: Icons.pending,
                  color: Colors.orange,
                  label: 'Pending',
                  value: _pendingTasks.toString(),
                ),
                const SizedBox(height: 8),
                _buildProgressItem(
                  icon: Icons.list_alt,
                  color: Colors.blue,
                  label: 'Total Tasks',
                  value: _totalTasks.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPendingSection() {
    final pendingTasks = _pendingTasksList;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pending_actions, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pending Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pendingTasks.length}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pendingTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _projects.isEmpty
                          ? 'Join a project'
                          : 'All tasks completed!',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...pendingTasks.map((task) => _buildPendingTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildPendingTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    final recentTasks = _recentTasks;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTasks.map((task) => _buildRecentTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildRecentTaskItem(Task task) {
    final isCompleted = task.isCompleted;
    final timeAgo = _getTimeAgo(task.lastModified ?? task.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.edit,
              size: 18,
              color: isCompleted ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCompleted ? 'Done' : 'In progress',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isCompleted
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
