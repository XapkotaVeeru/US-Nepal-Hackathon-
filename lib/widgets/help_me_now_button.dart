import 'package:flutter/material.dart';
import '../screens/crisis_resources_screen.dart';

class HelpMeNowButton extends StatelessWidget {
  const HelpMeNowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'help_me_now',
      onPressed: () => _showHelpSheet(context),
      backgroundColor: Theme.of(context).colorScheme.error,
      elevation: 8,
      child: const Icon(
        Icons.sos,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.errorContainer,
                      colorScheme.errorContainer.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety,
                        size: 32, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You matter.',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onErrorContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We\'re here to help you right now.',
                            style: TextStyle(
                                color: colorScheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Grounding Exercise
              _buildHelpOption(
                context,
                icon: Icons.spa_outlined,
                title: 'Grounding Exercise',
                subtitle: 'Quick breathing & calming technique',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _showGroundingExercise(context);
                },
              ),
              const SizedBox(height: 10),

              // Crisis Resources
              _buildHelpOption(
                context,
                icon: Icons.emergency_outlined,
                title: 'Crisis Resources',
                subtitle: '24/7 helplines & emergency contacts',
                color: colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CrisisResourcesScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Talk to someone
              _buildHelpOption(
                context,
                icon: Icons.chat_outlined,
                title: 'Talk to Someone Now',
                subtitle: 'Connect with a peer who understands',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Looking for an available peer supporter...'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Quick post
              _buildHelpOption(
                context,
                icon: Icons.edit_note,
                title: 'Quick Post',
                subtitle: 'Share what you\'re feeling right now',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to home and focus on post
                },
              ),

              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }

  void _showGroundingExercise(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.spa, color: Colors.teal),
            const SizedBox(width: 8),
            const Text('5-4-3-2-1 Grounding'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Take a deep breath and notice:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildGroundingStep(
                  '5', 'things you can SEE', Icons.visibility, Colors.blue),
              _buildGroundingStep(
                  '4', 'things you can TOUCH', Icons.touch_app, Colors.green),
              _buildGroundingStep(
                  '3', 'things you can HEAR', Icons.hearing, Colors.orange),
              _buildGroundingStep(
                  '2', 'things you can SMELL', Icons.air, Colors.purple),
              _buildGroundingStep(
                  '1', 'thing you can TASTE', Icons.restaurant, Colors.red),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '💛 You are safe. You are here. This moment will pass.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I feel better'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundingStep(
      String number, String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
