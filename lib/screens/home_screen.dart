import 'package:flutter/material.dart';
import '../widgets/create_post_card.dart';
import '../widgets/match_results_card.dart';
import '../models/post_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Post? _currentPost;
  bool _isLoading = false;

  void _onPostCreated(Post post) {
    setState(() {
      _currentPost = post;
      _isLoading = true;
    });

    // Simulate API call to backend for risk classification and matching
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _onCreateNewPost() {
    setState(() {
      _currentPost = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mental Health Support')),
      body: SafeArea(
        child: SingleChildScrollView(
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

              // Create post or show results
              if (_currentPost == null)
                CreatePostCard(onPostCreated: _onPostCreated)
              else if (_isLoading)
                _buildLoadingCard()
              else
                MatchResultsCard(
                  post: _currentPost!,
                  onCreateNewPost: _onCreateNewPost,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
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
