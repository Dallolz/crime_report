import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../sports/providers/sport_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/theme/app_theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int? _selectedSportId;

  @override
  Widget build(BuildContext context) {
    final sportsAsync = ref.watch(allSportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
      ),
      body: Column(
        children: [
          // Sport selector chips
          sportsAsync.when(
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (sports) {
              if (_selectedSportId == null && sports.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedSportId == null) {
                    setState(() {
                      _selectedSportId = sports.first['id'] as int;
                    });
                  }
                });
              }

              return SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sports.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final sport = sports[index];
                    final sportId = sport['id'] as int;
                    final isSelected = sportId == _selectedSportId;

                    return FilterChip(
                      selected: isSelected,
                      label: Text(sport['display_name'] as String? ?? ''),
                      onSelected: (_) {
                        setState(() => _selectedSportId = sportId);
                      },
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      showCheckmark: false,
                    );
                  },
                ),
              );
            },
          ),
          const Divider(height: 1),

          // Leaderboard list
          Expanded(
            child: _selectedSportId == null
                ? const Center(
                    child: Text(
                      'Sélectionnez un sport',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _LeaderboardList(sportId: _selectedSportId!),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  final int sportId;

  const _LeaderboardList({required this.sportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(sportId));

    return leaderboardAsync.when(
      loading: () => const LoadingWidget(message: 'Chargement du classement...'),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Erreur de chargement'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(leaderboardProvider(sportId)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (players) {
        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun joueur classé pour ce sport',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leaderboardProvider(sportId));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final entry = players[index];
              final player = entry['player'] as Map<String, dynamic>?;
              final rank = index + 1;
              final isTopThree = rank <= 3;

              return _LeaderboardTile(
                rank: rank,
                displayName: player?['display_name'] as String? ?? 'Joueur',
                avatarUrl: player?['avatar_url'] as String?,
                eloRating: entry['elo_rating'] as int? ?? 0,
                wins: entry['wins'] as int? ?? 0,
                matchesPlayed: entry['matches_played'] as int? ?? 0,
                isTopThree: isTopThree,
                onTap: () {
                  final playerId = player?['id'] as String?;
                  if (playerId != null) {
                    context.push('/profile/$playerId');
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String displayName;
  final String? avatarUrl;
  final int eloRating;
  final int wins;
  final int matchesPlayed;
  final bool isTopThree;
  final VoidCallback? onTap;

  const _LeaderboardTile({
    required this.rank,
    required this.displayName,
    this.avatarUrl,
    required this.eloRating,
    required this.wins,
    required this.matchesPlayed,
    this.isTopThree = false,
    this.onTap,
  });

  Color _medalColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.transparent;
    }
  }

  IconData? _medalIcon() {
    if (rank <= 3) return Icons.emoji_events;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isTopThree ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTopThree
            ? BorderSide(color: _medalColor().withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 40,
                child: isTopThree
                    ? Icon(_medalIcon(), color: _medalColor(), size: 28)
                    : Text(
                        '#$rank',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              const SizedBox(width: 8),

              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                backgroundColor: isTopThree
                    ? _medalColor().withOpacity(0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                child: avatarUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isTopThree
                              ? _medalColor()
                              : theme.colorScheme.onSurface,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name & stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isTopThree
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$wins V | $matchesPlayed matchs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // ELO
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isTopThree
                      ? _medalColor().withOpacity(0.15)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$eloRating',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTopThree
                        ? _medalColor()
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
