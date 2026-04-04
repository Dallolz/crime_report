import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sport_provider.dart';
import '../../../core/constants/sport_config.dart';
import '../../../core/widgets/player_card.dart';

class SportDetailScreen extends ConsumerWidget {
  final int sportId;

  const SportDetailScreen({super.key, required this.sportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportAsync = ref.watch(sportDetailProvider(sportId));
    final playersAsync = ref.watch(sportPlayersProvider(sportId));
    final matchesAsync = ref.watch(sportMatchesProvider(sportId));

    return sportAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (sport) {
        final config = SportConfig.getConfig(sport['name'] ?? '');
        return Scaffold(
          appBar: AppBar(
            title: Text(sport['display_name'] ?? 'Sport'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/matchmaking/create?sportId=$sportId'),
            icon: const Icon(Icons.add),
            label: const Text('Créer un match'),
          ),
          body: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Sport header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [config.color.withOpacity(0.2), config.color.withOpacity(0.05)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(config.icon, size: 48, color: config.color),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sport['display_name'] ?? '',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${sport['team_size_min']}-${sport['team_size_max']} joueurs | ${sport['default_duration_min']} min',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const TabBar(
                  tabs: [
                    Tab(text: 'Matchs'),
                    Tab(text: 'Joueurs'),
                    Tab(text: 'Classement'),
                  ],
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      // Matchs tab
                      matchesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (matches) => matches.isEmpty
                            ? const Center(child: Text('Aucun match ouvert'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: matches.length,
                                itemBuilder: (context, i) {
                                  final m = matches[i];
                                  final participantCount = m['participants'] is List
                                      ? (m['participants'] as List).length
                                      : 0;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      onTap: () => context.push('/matchmaking/${m['id']}'),
                                      title: Text(m['venue_name'] ?? 'Lieu non défini'),
                                      subtitle: Text(m['address'] ?? ''),
                                      trailing: Chip(
                                        label: Text('$participantCount/${m['max_players'] ?? '?'}'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Joueurs tab
                      playersAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (players) => players.isEmpty
                            ? const Center(child: Text('Aucun joueur'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: players.length,
                                itemBuilder: (context, i) {
                                  final p = players[i];
                                  final player = p['player'] as Map<String, dynamic>?;
                                  return PlayerCard(
                                    name: player?['display_name'] ?? player?['username'] ?? 'Joueur',
                                    avatarUrl: player?['avatar_url'],
                                    elo: p['elo_rating'] ?? 1000,
                                    skillLevel: p['skill_level'] ?? 'beginner',
                                    onTap: () {
                                      if (player != null) {
                                        context.push('/profile/${player['id']}');
                                      }
                                    },
                                  );
                                },
                              ),
                      ),

                      // Classement tab
                      _LeaderboardTab(sportId: sportId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final int sportId;

  const _LeaderboardTab({required this.sportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(sportId));

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (players) => players.isEmpty
          ? const Center(child: Text('Pas encore de classement'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              itemBuilder: (context, i) {
                final p = players[i];
                final player = p['player'] as Map<String, dynamic>?;
                final rank = i + 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  color: rank <= 3
                      ? [Colors.amber, Colors.grey[300], Colors.brown[200]][rank - 1]?.withOpacity(0.15)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank <= 3
                          ? [Colors.amber, Colors.grey, Colors.brown][rank - 1]
                          : Colors.grey[300],
                      child: Text(
                        '#$rank',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      player?['display_name'] ?? player?['username'] ?? 'Joueur',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${p['matches_played'] ?? 0} matchs | ${p['wins'] ?? 0} victoires'),
                    trailing: Text(
                      '${p['elo_rating'] ?? 1000}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    onTap: () {
                      if (player != null) context.push('/profile/${player['id']}');
                    },
                  ),
                );
              },
            ),
    );
  }
}
