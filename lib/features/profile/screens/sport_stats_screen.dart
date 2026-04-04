import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';
import '../../../core/widgets/rating_stars.dart';

class SportStatsScreen extends ConsumerWidget {
  final String userId;
  final int sportId;

  const SportStatsScreen({
    super.key,
    required this.userId,
    required this.sportId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      playerStatsProvider((userId: userId, sportId: sportId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (stats) => _buildStats(context, stats),
      ),
    );
  }

  Widget _buildStats(BuildContext context, Map<String, dynamic> stats) {
    final ps = stats['player_sport'] as Map<String, dynamic>;
    final totalReviews = stats['total_reviews'] as int;
    final avgRating = stats['avg_rating'] as double;
    final elo = ps['elo_rating'] as int;
    final matchesPlayed = ps['matches_played'] as int;
    final wins = ps['wins'] as int;
    final winRate = matchesPlayed > 0 ? (wins / matchesPlayed * 100).toStringAsFixed(1) : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ELO Rating card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Rating ELO', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '$elo',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ps['skill_level']?.toString().toUpperCase() ?? 'BEGINNER',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Matchs joués',
                  value: '$matchesPlayed',
                  icon: Icons.sports,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Victoires',
                  value: '$wins',
                  icon: Icons.emoji_events,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Win rate',
                  value: '$winRate%',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reputation
          Text(
            'Réputation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Note moyenne'),
                      Row(
                        children: [
                          RatingStars(rating: avgRating),
                          const SizedBox(width: 8),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total avis'),
                      Text(
                        '$totalReviews',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Score réputation'),
                      Text(
                        '${ps['reputation_score'] ?? 5.0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // XP
          Text(
            'Progression',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('XP dans ce sport'),
                      Text(
                        '${ps['xp'] ?? 0} XP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ((ps['xp'] ?? 0) % 1000) / 1000,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(ps['xp'] ?? 0) % 1000}/1000 XP pour le prochain niveau',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
