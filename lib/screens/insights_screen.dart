import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/journal_entry_model.dart';
import '../models/mood_entry_model.dart';
import '../providers/journal_provider.dart';
import '../providers/mood_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MoodProvider, JournalProvider>(
      builder: (context, moodProvider, journalProvider, _) {
        if ((moodProvider.isLoading && !moodProvider.isInitialized) ||
            (journalProvider.isLoading && !journalProvider.isInitialized)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final weeklyMoodData = _buildWeeklyMoodData(moodProvider.entries);
        final distribution = moodProvider.moodDistribution;
        final journalEntries = journalProvider.entries;
        final moodEntries = moodProvider.entries;
        final weeklyAverage = _weeklyAverageMood(weeklyMoodData);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Insights'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(context, weeklyAverage, moodEntries.length),
                const SizedBox(height: 20),
                _buildActivityStatsRow(
                  context,
                  journalCount: journalEntries.length,
                  moodCount: moodEntries.length,
                  streak: moodProvider.currentStreak,
                ),
                const SizedBox(height: 20),
                _buildWeeklyMoodChart(context, weeklyMoodData),
                const SizedBox(height: 20),
                _buildMoodDistributionChart(context, distribution),
                const SizedBox(height: 20),
                _buildEngagementCard(
                  context,
                  moodEntries: moodEntries,
                  journalEntries: journalEntries,
                  weeklyAverage: weeklyAverage,
                ),
                const SizedBox(height: 20),
                _buildWellnessStreakCard(
                  context,
                  streak: moodProvider.currentStreak,
                  weeklyMoodData: weeklyMoodData,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    double weeklyAverage,
    int moodCount,
  ) {
    final summary = moodCount == 0
        ? 'Start checking in to unlock your emotional wellness trends'
        : 'You logged $moodCount mood check-ins. Your weekly average is ${weeklyAverage.toStringAsFixed(1)}/5.';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              Icons.insights,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Weekly Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  Widget _buildActivityStatsRow(
    BuildContext context, {
    required int journalCount,
    required int moodCount,
    required int streak,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.edit_note,
            label: 'Journals',
            value: '$journalCount',
            color: Theme.of(context).colorScheme.primary,
            trend: journalCount == 0 ? 'Start writing' : 'Saved locally',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.mood,
            label: 'Check-ins',
            value: '$moodCount',
            color: Theme.of(context).colorScheme.secondary,
            trend: moodCount == 0 ? 'No data yet' : 'Persistent history',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '$streak',
            color: Theme.of(context).colorScheme.tertiary,
            trend: streak > 0 ? 'Days in a row' : 'Check in today',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String trend,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              trend,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMoodChart(
    BuildContext context,
    List<_MoodDayData> weeklyMoodData,
  ) {
    final hasData = weeklyMoodData.any((entry) => entry.mood > 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Weekly Mood Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasData
                  ? 'Your average mood across the last 7 days'
                  : 'Log mood check-ins to populate your weekly trend',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: hasData,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final moodLabels = ['', 'Very Low', 'Low', 'Neutral', 'Good', 'Great'];
                        final moodIndex = rod.toY.round().clamp(0, 5);
                        return BarTooltipItem(
                          moodIndex == 0 ? 'No check-in' : moodLabels[moodIndex],
                          TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weeklyMoodData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weeklyMoodData[index].day,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final emojis = ['', '😢', '😟', '😐', '😊', '😄'];
                          final index = value.toInt();
                          if (index >= 1 && index <= 5) {
                            return Text(emojis[index], style: const TextStyle(fontSize: 14));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: weeklyMoodData.asMap().entries.map((entry) {
                    final color = _getMoodColor(entry.value.mood);
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.mood,
                          color: color,
                          width: 28,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 5,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistributionChart(
    BuildContext context,
    Map<int, int> distribution,
  ) {
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);
    final sections = <PieChartSectionData>[];
    const labels = {
      5: 'Great',
      4: 'Good',
      3: 'Neutral',
      2: 'Low',
      1: 'Very Low',
    };

    for (final level in [5, 4, 3, 2, 1]) {
      final count = distribution[level] ?? 0;
      if (count == 0) continue;
      final percent = total == 0 ? 0 : (count / total) * 100;
      sections.add(
        PieChartSectionData(
          color: _getMoodColor(level.toDouble()),
          value: count.toDouble(),
          title: '${percent.round()}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Mood Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              total == 0
                  ? 'Your mood distribution will appear after your first check-ins'
                  : 'How your saved mood check-ins break down',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: total == 0
                        ? Center(
                            child: Text(
                              'No mood data yet',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                              sections: sections,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final level in [5, 4, 3, 2, 1]) ...[
                          _buildLegendItem(
                            '${labels[level]} (${distribution[level] ?? 0})',
                            _getMoodColor(level.toDouble()),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _buildEngagementCard(
    BuildContext context, {
    required List<MoodEntry> moodEntries,
    required List<JournalEntry> journalEntries,
    required double weeklyAverage,
  }) {
    final latestMood = moodEntries.isEmpty ? null : moodEntries.first;
    final latestJournal = journalEntries.isEmpty ? null : journalEntries.first;
    final journalWithPrompts = journalEntries.where((entry) => entry.prompt != null).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Engagement Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightRow(
              context,
              icon: Icons.mood,
              label: 'Latest Mood',
              value: latestMood == null ? 'No check-in yet' : _moodLabel(latestMood.moodLevel),
            ),
            const Divider(height: 24),
            _buildInsightRow(
              context,
              icon: Icons.menu_book,
              label: 'Latest Journal',
              value: latestJournal == null ? 'No journal yet' : _timeAgo(latestJournal.createdAt),
            ),
            const Divider(height: 24),
            _buildInsightRow(
              context,
              icon: Icons.analytics_outlined,
              label: 'Weekly Avg Mood',
              value: moodEntries.isEmpty ? 'No data' : '${weeklyAverage.toStringAsFixed(1)}/5',
            ),
            const Divider(height: 24),
            _buildInsightRow(
              context,
              icon: Icons.lightbulb_outline,
              label: 'Prompt-Based Entries',
              value: '$journalWithPrompts of ${journalEntries.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildWellnessStreakCard(
    BuildContext context, {
    required int streak,
    required List<_MoodDayData> weeklyMoodData,
  }) {
    final activeDays = weeklyMoodData.where((entry) => entry.mood > 0).length;

    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              streak == 0 ? 'Start Your Streak' : '$streak Day Streak!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              streak == 0
                  ? 'Check in today to begin building consistent wellness habits.'
                  : 'You have checked in on $activeDays of the last 7 days. Keep the rhythm going.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: weeklyMoodData.map((entry) {
                final hasEntry = entry.mood > 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Icon(
                        hasEntry ? Icons.check_circle : Icons.circle_outlined,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.day.characters.first,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<_MoodDayData> _buildWeeklyMoodData(List<MoodEntry> entries) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final sameDayEntries = entries.where((entry) {
        return entry.createdAt.year == day.year &&
            entry.createdAt.month == day.month &&
            entry.createdAt.day == day.day;
      }).toList();

      double mood = 0;
      if (sameDayEntries.isNotEmpty) {
        mood = sameDayEntries
                .map((entry) => entry.moodLevel)
                .reduce((a, b) => a + b) /
            sameDayEntries.length;
      }

      return _MoodDayData(labels[day.weekday - 1], mood);
    });
  }

  double _weeklyAverageMood(List<_MoodDayData> weeklyMoodData) {
    final values = weeklyMoodData.where((entry) => entry.mood > 0).map((entry) => entry.mood).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _moodLabel(int moodLevel) {
    switch (moodLevel) {
      case 5:
        return 'Great';
      case 4:
        return 'Good';
      case 3:
        return 'Neutral';
      case 2:
        return 'Low';
      default:
        return 'Very Low';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getMoodColor(double mood) {
    if (mood >= 4.5) return Colors.green.shade500;
    if (mood >= 3.5) return Colors.lightGreen.shade500;
    if (mood >= 2.5) return Colors.amber.shade500;
    if (mood >= 1.5) return Colors.orange.shade500;
    if (mood > 0) return Colors.red.shade500;
    return Colors.grey.shade300;
  }
}

class _MoodDayData {
  final String day;
  final double mood;

  const _MoodDayData(this.day, this.mood);
}
