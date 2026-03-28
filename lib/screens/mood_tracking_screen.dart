import 'package:flutter/material.dart';

// ── Design tokens (mirrored from main.dart) ──────────────────────────────────
class _C {
  static const sage = Color(0xFF52A77A);
  static const sageLight = Color(0xFF7EC8A0);
  static const cream = Color(0xFFF7F5F0);
  static const creamDark = Color(0xFFEDE9E0);
  static const amber = Color(0xFFE8A838);
  static const ink = Color(0xFF1C2B2A);
  static const inkLight = Color(0xFF5C706C);
  static const inkMuted = Color(0xFF9AACAA);
  static const darkSurface = Color(0xFF14201E);
  static const darkCard = Color(0xFF1F2E2B);
  static const darkBorder = Color(0xFF2C3F3B);
}

// ── Data models ───────────────────────────────────────────────────────────────
class _MoodOption {
  final String emoji;
  final String label;
  final Color color;
  const _MoodOption(this.emoji, this.label, this.color);
}

class _MoodEntry {
  final DateTime date;
  final int moodLevel; // 1–5
  final String note;
  const _MoodEntry(this.date, this.moodLevel, this.note);
}

// ── Screen ────────────────────────────────────────────────────────────────────
class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedMoodIndex;
  final TextEditingController _noteController = TextEditingController();
  bool _todayCheckedIn = false;
  late final AnimationController _checkAnim;

  static const List<_MoodOption> _moods = [
    _MoodOption('😢', 'Very Low', Color(0xFFE05C5C)),
    _MoodOption('😟', 'Low', Color(0xFFE8923A)),
    _MoodOption('😐', 'Neutral', Color(0xFFE8C438)),
    _MoodOption('😊', 'Good', Color(0xFF7BC67A)),
    _MoodOption('😄', 'Great', Color(0xFF52A77A)),
  ];

  final List<_MoodEntry> _moodHistory = [
    _MoodEntry(DateTime.now().subtract(const Duration(days: 1)), 4,
        'Had a great chat with a peer today!'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 2)), 3,
        'Feeling okay, just a bit stressed about exams.'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 3)), 2,
        'Rough day. Talked to my support group though.'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 4)), 4,
        'Exercise really helped my mood today.'),
    _MoodEntry(
        DateTime.now().subtract(const Duration(days: 5)), 3, ''),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 6)), 5,
        'Best day in a while! Feeling supported.'),
    _MoodEntry(DateTime.now().subtract(const Duration(days: 7)), 4,
        'Good conversations in group chat.'),
  ];

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _checkAnim.dispose();
    super.dispose();
  }

  void _submitMood() {
    if (_selectedMoodIndex == null) return;
    setState(() {
      _todayCheckedIn = true;
      _moodHistory.insert(
        0,
        _MoodEntry(DateTime.now(), _selectedMoodIndex! + 1,
            _noteController.text.trim()),
      );
    });
    _checkAnim.forward(from: 0);
    _noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Mood logged: ${_moods[_selectedMoodIndex!].label} ✓'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.sage,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _colorForLevel(int l) => _moods[(l - 1).clamp(0, 4)].color;
  String _emojiForLevel(int l) => _moods[(l - 1).clamp(0, 4)].emoji;
  String _labelForLevel(int l) => _moods[(l - 1).clamp(0, 4)].label;

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _C.darkSurface : _C.cream,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CheckInCard(
              isDark: isDark,
              moods: _moods,
              selectedIndex: _selectedMoodIndex,
              noteController: _noteController,
              checkedIn: _todayCheckedIn,
              checkAnim: _checkAnim,
              onMoodSelected: (i) =>
                  setState(() => _selectedMoodIndex = i),
              onSubmit: _submitMood,
            ),
            const SizedBox(height: 20),
            _WeekCalendar(
              isDark: isDark,
              moodHistory: _moodHistory,
              colorForLevel: _colorForLevel,
              emojiForLevel: _emojiForLevel,
            ),
            const SizedBox(height: 20),
            _SectionHeader(label: 'Recent Moods', isDark: isDark),
            const SizedBox(height: 10),
            ..._moodHistory.take(7).map(
                  (e) => _HistoryTile(
                    entry: e,
                    isDark: isDark,
                    color: _colorForLevel(e.moodLevel),
                    emoji: _emojiForLevel(e.moodLevel),
                    label: _labelForLevel(e.moodLevel),
                    timeAgo: _timeAgo(e.date),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _C.darkSurface : _C.cream,
          border: Border(
            bottom: BorderSide(
              color: isDark ? _C.darkBorder : _C.creamDark,
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFFE8F0EE)
                      : _C.ink,
                ),
              ),
              const Spacer(),
              Text(
                'Mood Tracking',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFE8F0EE)
                      : _C.ink,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              // Balance the back button
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Check-in Card ─────────────────────────────────────────────────────────────
class _CheckInCard extends StatelessWidget {
  final bool isDark;
  final List<_MoodOption> moods;
  final int? selectedIndex;
  final TextEditingController noteController;
  final bool checkedIn;
  final AnimationController checkAnim;
  final ValueChanged<int> onMoodSelected;
  final VoidCallback onSubmit;

  const _CheckInCard({
    required this.isDark,
    required this.moods,
    required this.selectedIndex,
    required this.noteController,
    required this.checkedIn,
    required this.checkAnim,
    required this.onMoodSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (checkedIn) return _ChecedInBanner(isDark: isDark, anim: checkAnim);

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _C.sage.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_outline_rounded,
                    color: _C.sage, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE8F0EE)
                          : _C.ink,
                    ),
                  ),
                  Text(
                    'Tap an emoji to log your mood',
                    style: TextStyle(
                        fontSize: 12, color: _C.inkMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Emoji selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.asMap().entries.map((e) {
              final i = e.key;
              final mood = e.value;
              final sel = selectedIndex == i;
              return GestureDetector(
                onTap: () => onMoodSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? mood.color.withOpacity(0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel
                          ? mood.color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                            fontSize: sel ? 38 : 28),
                        child: Text(mood.emoji),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: sel
                              ? mood.color
                              : _C.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Selected mood label banner
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: selectedIndex != null
                ? Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: moods[selectedIndex!]
                          .color
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(moods[selectedIndex!].emoji,
                            style:
                                const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Feeling ${moods[selectedIndex!].label}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                moods[selectedIndex!].color,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Note input
          TextField(
            controller: noteController,
            maxLines: 3,
            maxLength: 200,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFFE8F0EE)
                  : _C.ink,
            ),
            decoration: InputDecoration(
              hintText:
                  'Add a note about your day (optional)…',
              hintStyle:
                  const TextStyle(color: _C.inkMuted, fontSize: 14),
              filled: true,
              fillColor: isDark ? _C.darkBorder : _C.creamDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle:
                  const TextStyle(color: _C.inkMuted, fontSize: 11),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          const SizedBox(height: 14),

          // Submit button
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed:
                  selectedIndex != null ? onSubmit : null,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                'Log My Mood',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _C.sage,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _C.inkMuted.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Checked-in banner ─────────────────────────────────────────────────────────
class _ChecedInBanner extends StatelessWidget {
  final bool isDark;
  final AnimationController anim;
  const _ChecedInBanner(
      {required this.isDark, required this.anim});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                  parent: anim, curve: Curves.elasticOut),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _C.sage.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 32, color: _C.sage),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "You've checked in today! 🌿",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.sage,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Come back tomorrow to continue your streak',
              style: TextStyle(fontSize: 13, color: _C.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week Calendar ─────────────────────────────────────────────────────────────
class _WeekCalendar extends StatelessWidget {
  final bool isDark;
  final List<_MoodEntry> moodHistory;
  final Color Function(int) colorForLevel;
  final String Function(int) emojiForLevel;

  const _WeekCalendar({
    required this.isDark,
    required this.moodHistory,
    required this.colorForLevel,
    required this.emojiForLevel,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'This Week',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _C.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.sage.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '7-day view',
                  style: TextStyle(
                    fontSize: 11,
                    color: _C.sage,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = now
                  .subtract(Duration(days: now.weekday - 1 - i));
              final isToday = day.day == now.day &&
                  day.month == now.month;
              final entries = moodHistory.where((e) =>
                  e.date.day == day.day &&
                  e.date.month == day.month &&
                  e.date.year == day.year);
              final hasMood = entries.isNotEmpty;
              final level =
                  hasMood ? entries.first.moodLevel : 0;

              return Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color:
                          isToday ? _C.sage : _C.inkMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: hasMood
                          ? colorForLevel(level)
                              .withOpacity(0.15)
                          : (isDark
                              ? _C.darkBorder
                              : _C.creamDark),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(
                              color: _C.sage, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: hasMood
                          ? Text(
                              emojiForLevel(level),
                              style: const TextStyle(
                                  fontSize: 18),
                            )
                          : Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(
                                        0xFF9AACAA)
                                    : _C.inkMuted,
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
    );
  }
}

// ── History Tile ──────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final _MoodEntry entry;
  final bool isDark;
  final Color color;
  final String emoji;
  final String label;
  final String timeAgo;

  const _HistoryTile({
    required this.entry,
    required this.isDark,
    required this.color,
    required this.emoji,
    required this.label,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? _C.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? _C.darkBorder : _C.creamDark,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Emoji badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF9AACAA)
                            : _C.inkLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time
            Text(
              timeAgo,
              style: const TextStyle(
                  fontSize: 11, color: _C.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader(
      {required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE8F0EE) : _C.ink,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? _C.darkBorder : _C.creamDark,
          ),
        ),
      ],
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _C.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? _C.darkBorder : _C.creamDark,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _C.ink.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}