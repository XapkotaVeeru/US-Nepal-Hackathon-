import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CrisisResourcesScreen extends StatelessWidget {
  const CrisisResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crisis Resources'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Emergency Banner
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(children: [
                  Icon(Icons.emergency, size: 40, color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(height: 12),
                  Text('If you\'re in immediate danger, call 911',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _launchUrl('tel:911'),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call 911'),
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            Text('24/7 Crisis Helplines', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildResourceCard(context,
              name: '988 Suicide & Crisis Lifeline',
              phone: '988',
              description: 'Free, confidential 24/7 support for people in distress.',
              url: 'https://988lifeline.org',
              icon: Icons.favorite,
              is24x7: true,
            ),
            _buildResourceCard(context,
              name: 'Crisis Text Line',
              phone: 'Text HOME to 741741',
              description: 'Free, 24/7 crisis support via text message.',
              url: 'https://www.crisistextline.org',
              icon: Icons.textsms,
              is24x7: true,
            ),
            _buildResourceCard(context,
              name: 'NAMI Helpline',
              phone: '1-800-950-6264',
              description: 'Mental health information, referrals, and support.',
              url: 'https://www.nami.org/help',
              icon: Icons.psychology,
              is24x7: false,
            ),
            _buildResourceCard(context,
              name: 'SAMHSA National Helpline',
              phone: '1-800-662-4357',
              description: 'Treatment referral service for mental health & substance use.',
              url: 'https://www.samhsa.gov/find-help/national-helpline',
              icon: Icons.health_and_safety,
              is24x7: true,
            ),
            _buildResourceCard(context,
              name: 'Boys Town National Hotline',
              phone: '1-800-448-3000',
              description: 'Crisis support and counseling for young people and families.',
              url: 'https://www.boystown.org/hotline',
              icon: Icons.diversity_3,
              is24x7: true,
            ),

            const SizedBox(height: 20),
            Text('Nepal Resources', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildResourceCard(context,
              name: 'TPO Nepal',
              phone: '+977-1-4431717',
              description: 'Psychosocial support and mental health services in Nepal.',
              url: 'https://www.tponepal.org',
              icon: Icons.local_hospital,
              is24x7: false,
            ),
            _buildResourceCard(context,
              name: 'CMC Nepal Mental Health',
              phone: '1166',
              description: 'Nepal mental health helpline for crisis support.',
              url: null,
              icon: Icons.phone_in_talk,
              is24x7: true,
            ),

            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Important Reminder', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  Text('This app provides peer support, not professional therapy. If you or someone you know is in crisis, please use the resources above.',
                    style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, {
    required String name, required String phone, required String description,
    required String? url, required IconData icon, required bool is24x7,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (is24x7) Text('24/7 Available', style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w600)),
            ])),
          ]),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _launchUrl('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}'),
              icon: const Icon(Icons.phone, size: 16), label: Text(phone, style: const TextStyle(fontSize: 12)),
            )),
            if (url != null) ...[
              const SizedBox(width: 8),
              IconButton.outlined(onPressed: () => _launchUrl(url), icon: const Icon(Icons.open_in_new, size: 18)),
            ],
          ]),
        ]),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
