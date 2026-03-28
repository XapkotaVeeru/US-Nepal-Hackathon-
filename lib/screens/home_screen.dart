import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/create_post_card.dart';
import '../widgets/match_results_card.dart';
import '../providers/app_state_provider.dart';
import '../providers/post_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateProvider, PostProvider>(
      builder: (context, appState, postProvider, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You\'re not alone',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share how you\'re feeling and connect with others who understand.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              if (postProvider.error != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            postProvider.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => postProvider.clearError(),
                        ),
                      ],
                    ),
                  ),
                ),

              if (postProvider.error != null) const SizedBox(height: 16),

              // Create post or show results
              if (postProvider.matchResults == null)
                CreatePostCard(
                  anonymousId: appState.anonymousId ?? '',
                  isSubmitting: postProvider.isSubmitting,
                )
              else if (postProvider.isSubmitting)
                _buildLoadingCard(context)
              else
                MatchResultsCard(
                  post: postProvider.currentPost!,
                  onCreateNewPost: () => postProvider.clearMatchResults(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Finding people who understand...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re looking for people with similar experiences.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
