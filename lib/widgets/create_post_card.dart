import 'package:flutter/material.dart';
import '../models/post_model.dart';

class CreatePostCard extends StatefulWidget {
  final Function(Post) onPostCreated;

  const CreatePostCard({
    super.key,
    required this.onPostCreated,
  });

  @override
  State<CreatePostCard> createState() => _CreatePostCardState();
}

class _CreatePostCardState extends State<CreatePostCard> {
  final TextEditingController _controller = TextEditingController();
  bool _consentGiven = false;
  bool _showGuidelines = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _characterCount => _controller.text.length;
  bool get _isValid =>
      _characterCount >= 50 && _characterCount <= 2000 && _consentGiven;

  void _submitPost() {
    if (!_isValid) return;

    final post = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _controller.text,
      createdAt: DateTime.now(),
      riskLevel: RiskLevel.low, // Will be determined by backend
    );

    widget.onPostCreated(post);
    _controller.clear();
    setState(() {
      _consentGiven = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Safety Guidelines
        if (_showGuidelines)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Important Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showGuidelines = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• This is peer support, not professional therapy\n'
                    '• Your information is anonymous and private\n'
                    '• We match your feelings to find similar experiences\n'
                    '• If you\'re in crisis, we\'ll show emergency resources',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Create Post Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your thoughts and feelings. We\'ll help you connect with others who understand.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // Text input
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText:
                        'I feel overwhelmed with studies and don\'t know how to handle the pressure...',
                    border: const OutlineInputBorder(),
                    counterText: '$_characterCount/2000 (min: 50)',
                    counterStyle: TextStyle(
                      color: _characterCount < 50
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Consent checkbox
                CheckboxListTile(
                  value: _consentGiven,
                  onChanged: (value) {
                    setState(() {
                      _consentGiven = value ?? false;
                    });
                  },
                  title: const Text(
                    'I understand my text will be used by AI to find support',
                  ),
                  subtitle: const Text(
                    'Your data is anonymous and will be used only for matching',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // Submit button
                FilledButton.icon(
                  onPressed: _isValid ? _submitPost : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Post'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
