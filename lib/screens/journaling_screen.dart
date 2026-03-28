import 'package:flutter/material.dart';

class JournalingScreen extends StatefulWidget {
  const JournalingScreen({super.key});

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _newEntryController = TextEditingController();
  String? _selectedPrompt;

  final List<String> _prompts = [
    '💭 What made you smile today?',
    '🌟 Name one thing you\'re grateful for.',
    '🎯 What\'s one small goal for tomorrow?',
    '💪 What challenge did you overcome recently?',
    '🌈 Describe a moment of peace from today.',
    '🤝 Who supported you this week and how?',
  ];

  final List<_JournalEntry> _entries = [
    _JournalEntry(
      id: '1',
      title: 'A better day',
      content: 'Today was actually a good day. I reached out to my support group and had a meaningful conversation about managing academic stress.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      mood: '😊',
      prompt: 'What made you smile today?',
    ),
    _JournalEntry(
      id: '2',
      title: 'Rough start, gentle ending',
      content: 'Woke up feeling anxious about my midterms. But after the breathing exercise and talking to Anonymous Butterfly, I felt calmer.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      mood: '😐',
      prompt: null,
    ),
    _JournalEntry(
      id: '3',
      title: 'Grateful for connections',
      content: 'I\'m grateful for the anonymous support system. Being able to share without judgment has been incredibly healing.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      mood: '😄',
      prompt: 'Name one thing you\'re grateful for.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newEntryController.dispose();
    super.dispose();
  }

  void _addEntry() {
    if (_newEntryController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least 10 characters'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() {
      _entries.insert(0, _JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _newEntryController.text.trim().length > 30
            ? '${_newEntryController.text.trim().substring(0, 30)}...'
            : _newEntryController.text.trim(),
        content: _newEntryController.text.trim(),
        createdAt: DateTime.now(),
        mood: '😊',
        prompt: _selectedPrompt,
      ));
      _newEntryController.clear();
      _selectedPrompt = null;
      _tabController.animateTo(1);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal entry saved! 📝'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Write'),
            Tab(icon: Icon(Icons.book), text: 'Entries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWriteTab(context), _buildEntriesTab(context)],
      ),
    );
  }

  Widget _buildWriteTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need inspiration? Try a prompt:', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _prompts.map((prompt) {
                      return ChoiceChip(
                        label: Text(prompt, style: const TextStyle(fontSize: 12)),
                        selected: _selectedPrompt == prompt,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPrompt = selected ? prompt : null;
                            if (selected) _newEntryController.text = '${prompt.substring(2)}\n\n';
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.auto_fix_high, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Write freely — your safe space', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newEntryController, maxLines: 10, maxLength: 5000,
                    decoration: InputDecoration(
                      hintText: 'Start writing... Your thoughts are private.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _addEntry, icon: const Icon(Icons.save), label: const Text('Save Entry'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesTab(BuildContext context) {
    if (_entries.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.book_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('No journal entries yet', style: Theme.of(context).textTheme.titleLarge),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final diff = DateTime.now().difference(entry.createdAt);
        final timeAgo = diff.inHours < 24 ? '${diff.inHours}h ago' : '${diff.inDays}d ago';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEntryDetail(context, entry),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(entry.mood, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(timeAgo, style: Theme.of(context).textTheme.bodySmall),
                  ])),
                ]),
                const SizedBox(height: 12),
                Text(entry.content, maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _showEntryDetail(BuildContext context, _JournalEntry entry) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc, padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Text(entry.mood, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 20),
            Text(entry.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

class _JournalEntry {
  final String id, title, content, mood;
  final DateTime createdAt;
  final String? prompt;
  _JournalEntry({required this.id, required this.title, required this.content, required this.createdAt, required this.mood, this.prompt});
}
