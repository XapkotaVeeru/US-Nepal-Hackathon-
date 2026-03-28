import 'package:flutter/material.dart';

class ConversationStarters extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const ConversationStarters({
    super.key,
    required this.onSuggestionTap,
  });

  static const List<Map<String, dynamic>> _icebreakers = [
    {
      'text': 'I read your post and I\'m here for you. 💛',
      'icon': Icons.favorite_outline,
    },
    {
      'text': 'I\'m going through something similar.',
      'icon': Icons.people_outline,
    },
    {
      'text': 'How are you feeling right now?',
      'icon': Icons.mood_outlined,
    },
    {
      'text': 'Would you like to talk about it?',
      'icon': Icons.chat_bubble_outline,
    },
    {
      'text': 'You\'re not alone in this. 🌟',
      'icon': Icons.star_outline,
    },
    {
      'text': 'Take your time — I\'m here whenever you\'re ready.',
      'icon': Icons.access_time_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Conversation starters',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _icebreakers.length,
              itemBuilder: (context, index) {
                final icebreaker = _icebreakers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onSuggestionTap(icebreaker['text'] as String),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icebreaker['icon'] as IconData,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            icebreaker['text'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
