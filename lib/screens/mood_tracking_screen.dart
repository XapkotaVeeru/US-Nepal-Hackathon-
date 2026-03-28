import 'package:flutter/material.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  int? _selectedMoodIndex;
  final TextEditingController _noteController = TextEditingController();
  bool _todayCheckedIn = false;

  final List<_MoodOption> _moods = [
    _MoodOption('😢', 'Very Low', Colors.red),
    _MoodOption('😟', 'Low', Colors.orange),
    _MoodOption('😐', 'Neutral', Colors.amber),
    _MoodOption('😊', 'Good', Colors.lightGreen),
    _MoodOption('😄', 'Great', Colors.green),
  ];

  // Mock mood history
  final List<_MoodEntry> _moodHistory = [
    _MoodEntry(DateTime.now().subtract(const Duration(days: 1)), 4, 'Had a great chat with a peer today!'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 2)), 3, 'Feeling okay, just a bit stressed about exams.'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 3)), 2, 'Rough day. Talked to my support group though.'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 4)), 4, 'Exercise really helped my mood today.'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 5)), 3, ''),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 6)), 5, 'Best day in a while! Feeling supported.'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 7)), 4, 'Good conversations in group chat.'),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitMood() {
    if (_selectedMoodIndex == null) return;

    setState(() {
      _todayCheckedIn = true;
      _moodHistory.insert(
        0,
        _MoodEntry(
          DateTime.now(),
          _selectedMoodIndex! + 1,
          _noteController.text.trim(),
        ),
      );
    });

    _noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mood logged: ${_moods[_selectedMoodIndex!].label}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracking'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Check-in
            _buildCheckInCard(context),
            const SizedBox(height: 20),

            // Weekly Mood Calendar
            _buildWeekCalendar(context),
            const SizedBox(height: 20),

            // Mood History
            _buildMoodHistoryList(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInCard(BuildContext context) {
    if (_todayCheckedIn) {
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 12),
              Text(
                'You\'ve checked in today!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Come back tomorrow to continue your streak',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap an emoji to log your mood',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Mood Emoji Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moods.asMap().entries.map((entry) {
                final index = entry.key;
                final mood = entry.value;
                final isSelected = _selectedMoodIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMoodIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? mood.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: mood.color, width: 2.5)
                          : Border.all(
                              color: Colors.transparent, width: 2.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          mood.emoji,
                          style: TextStyle(
                            fontSize: isSelected ? 36 : 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? mood.color : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Optional note
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Add a note about your day (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 12),

            // Submit button
            FilledButton.icon(
              onPressed: _selectedMoodIndex != null ? _submitMood : null,
              icon: const Icon(Icons.check),
              label: const Text('Log Mood'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCalendar(BuildContext context) {
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final day = now.subtract(Duration(days: now.weekday - 1 - index));
                final isToday = day.day == now.day;
                final entry = _moodHistory.where((e) {
                  return e.date.day == day.day &&
                      e.date.month == day.month &&
                      e.date.year == day.year;
                });
                final hasMood = entry.isNotEmpty;
                final moodValue = hasMood ? entry.first.moodLevel : 0;

                return Column(
                  children: [
                    Text(
                      weekDays[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasMood
                            ? _getMoodColorForLevel(moodValue)
                                .withValues(alpha: 0.2)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          hasMood
                              ? _getMoodEmoji(moodValue)
                              : '${day.day}',
                          style: TextStyle(
                            fontSize: hasMood ? 18 : 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodHistoryList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Moods',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...(_moodHistory.take(7).map(
              (entry) => _buildMoodHistoryTile(context, entry),
            )),
      ],
    );
  }

  Widget _buildMoodHistoryTile(BuildContext context, _MoodEntry entry) {
    final color = _getMoodColorForLevel(entry.moodLevel);
    final diff = DateTime.now().difference(entry.date);
    String timeAgo;
    if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = '${diff.inDays}d ago';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getMoodEmoji(entry.moodLevel),
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(
          _getMoodLabel(entry.moodLevel),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: entry.note.isNotEmpty
            ? Text(
                entry.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(
          timeAgo,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Color _getMoodColorForLevel(int level) {
    switch (level) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1:
        return '😢';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Unknown';
    }
  }
}

class _MoodOption {
  final String emoji;
  final String label;
  final Color color;

  _MoodOption(this.emoji, this.label, this.color);
}

class _MoodEntry {
  final DateTime date;
  final int moodLevel;
  final String note;

  _MoodEntry(this.date, this.moodLevel, this.note);
}
