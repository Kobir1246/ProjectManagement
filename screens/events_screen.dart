import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event.dart';

class EventsScreen extends StatefulWidget {
  final List<Event> events;
  final Function(Event) onEventCreated;
  final Function(String) onNotifyMembers;
  final Function(String) onDeleteEvent;

  const EventsScreen({
    super.key,
    required this.events,
    required this.onEventCreated,
    required this.onNotifyMembers,
    required this.onDeleteEvent,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = 'upcoming';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Event> get _filteredEvents {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'past':
        return widget.events.where((e) => e.dateTime.isBefore(now)).toList();
      case 'all':
        return widget.events;
      default:
        return widget.events.where((e) => e.dateTime.isAfter(now)).toList();
    }
  }

  String _getCountdown(Event event) {
    final now = DateTime.now();
    final diff = event.dateTime.difference(now);

    if (diff.isNegative) return 'Started';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Starting soon';
  }

  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
            if (event.projectName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(event.projectName!),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  event.notified
                      ? Icons.notifications
                      : Icons.notifications_off,
                  size: 18,
                  color: event.notified ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  event.notified ? 'Members notified' : 'Members not notified',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: Text('Are you sure you want to cancel "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteEvent(event.title);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Upcoming', 'upcoming'),
                const SizedBox(width: 8),
                _buildFilterChip('Past', 'past'),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Events Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create events to schedule meetings',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = _filteredEvents[index];
                    return _buildEventCard(event);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C4DFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final isPast = event.dateTime.isBefore(DateTime.now());
    final isToday = _isToday(event.dateTime);
    final countdown = _getCountdown(event);
    final isUrgent =
        !isPast && event.dateTime.difference(DateTime.now()).inHours < 24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent ? Border.all(color: Colors.red, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade100
                        : const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.dateTime.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey : const Color(0xFF7C4DFF),
                        ),
                      ),
                      Text(
                        _getMonthAbbr(event.dateTime.month),
                        style: TextStyle(
                          fontSize: 12,
                          color: isPast ? Colors.grey : const Color(0xFF7C4DFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isPast
                              ? TextDecoration.lineThrough
                              : null,
                          color: isPast ? Colors.grey : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_getTimeString(event.dateTime)}${isToday ? ' - Today' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (event.projectName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.projectName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                  onSelected: (value) {
                    if (value == 'details') {
                      _showEventDetails(event);
                    } else if (value == 'cancel') {
                      _showDeleteConfirmation(event);
                    } else if (value == 'notify') {
                      widget.onNotifyMembers(event.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    if (!event.notified)
                      const PopupMenuItem(
                        value: 'notify',
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active, size: 20),
                            SizedBox(width: 8),
                            Text('Notify Members'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Cancel Event',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isPast) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: isUrgent ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Starts in: $countdown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUrgent ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  String _getTimeString(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
