import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App Logo
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.favorite,
                  size: 48, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Mental Health Support',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Version 1.0.0',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 8),
            Text('AI-Based Anonymous Peer Support',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),

            // Mission Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Our Mission',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                      const SizedBox(height: 8),
                      Text(
                          'To create a safe, anonymous space where people can connect with others who understand their struggles. Using AI, we match you with peers facing similar challenges, ensuring no one has to face difficult times alone.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  height: 1.5)),
                    ]),
              ),
            ),
            const SizedBox(height: 16),

            // Features
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Key Features',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildFeatureItem(context, Icons.shield,
                          'Complete Anonymity', 'No personal data required'),
                      _buildFeatureItem(
                          context,
                          Icons.psychology,
                          'AI-Powered Matching',
                          'Find peers with similar experiences'),
                      _buildFeatureItem(context, Icons.chat_bubble, 'Peer Chat',
                          '1-on-1 and group conversations'),
                      _buildFeatureItem(context, Icons.insights,
                          'Mood Insights', 'Track your emotional wellness'),
                      _buildFeatureItem(context, Icons.emergency,
                          'Crisis Support', 'Immediate access to helplines'),
                      _buildFeatureItem(context, Icons.cloud, 'Powered by AWS',
                          'Bedrock AI & secure cloud infrastructure'),
                    ]),
              ),
            ),
            const SizedBox(height: 16),

            // Tech Stack
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Built With',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _buildTechChip(context, '💙 Flutter'),
                        _buildTechChip(context, '☁️ AWS Bedrock'),
                        _buildTechChip(context, '🤖 AI/ML'),
                        _buildTechChip(context, '🔒 End-to-End Encryption'),
                        _buildTechChip(context, '⚡ WebSocket'),
                        _buildTechChip(context, '�️ DynamoDB'),
                      ]),
                    ]),
              ),
            ),
            const SizedBox(height: 16),

            // Hackathon
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(children: [
                  const Text('🏆', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text('US-Nepal Hackathon 2026',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer)),
                  const SizedBox(height: 4),
                  Text('Built with ❤️ for mental health awareness',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.warning_amber,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Text('Important Disclaimer',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          'This app is not a replacement for professional therapy or medical advice. If you are in crisis, please contact emergency services or use the crisis resources provided.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer)),
                    ]),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]),
    );
  }

  Widget _buildTechChip(BuildContext context, String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
