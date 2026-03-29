import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';

class CreatePostCard extends StatefulWidget {
  final String anonymousId;
  final bool isSubmitting;

  const CreatePostCard({
    super.key,
    required this.anonymousId,
    this.isSubmitting = false,
  });

  @override
  State<CreatePostCard> createState() => _CreatePostCardState();
}

class _CreatePostCardState extends State<CreatePostCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _consentGiven = false;
  bool _showGuidelines = true;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _characterCount => _controller.text.length;

  // Lowered minimum to 20 chars for a better UX — still requires consent
  bool get _isValid =>
      _characterCount >= 20 && _characterCount <= 2000 && _consentGiven;

  void _submitPost() {
    if (!_isValid || widget.isSubmitting) return;

    // Unfocus the text field first so the keyboard dismisses
    _focusNode.unfocus();

    final postProvider = context.read<PostProvider>();
    postProvider.submitPost(
      anonymousId: widget.anonymousId,
      content: _controller.text,
    );

    _controller.clear();
    setState(() {
      _consentGiven = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Safety Guidelines
        if (_showGuidelines)
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Important Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
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
                          color: colorScheme.onPrimaryContainer,
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

                // Text input — uses a FocusNode for reliable keyboard handling
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 6,
                  minLines: 3,
                  maxLength: 2000,
                  enabled: !widget.isSubmitting,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText:
                        'I feel overwhelmed with studies and don\'t know how to handle the pressure...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    counterText: '$_characterCount / 2000 (min 20)',
                    counterStyle: TextStyle(
                      color: _characterCount < 20
                          ? colorScheme.error
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Consent checkbox
                GestureDetector(
                  onTap: widget.isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _consentGiven = !_consentGiven;
                          });
                        },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _consentGiven,
                          onChanged: widget.isSubmitting
                              ? null
                              : (value) {
                                  setState(() {
                                    _consentGiven = value ?? false;
                                  });
                                },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I understand my text will be used by AI to find support',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your data is anonymous and used only for matching',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.outline,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submit button
                FilledButton.icon(
                  onPressed:
                      _isValid && !widget.isSubmitting ? _submitPost : null,
                  icon: widget.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                      widget.isSubmitting ? 'Analyzing...' : 'Share & Find Support'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Helper text when button is disabled
                if (!_isValid && !widget.isSubmitting)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _characterCount < 20
                          ? 'Write at least 20 characters to share'
                          : !_consentGiven
                              ? 'Please check the consent box above'
                              : '',
                      style: TextStyle(
                        color: colorScheme.error.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
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
