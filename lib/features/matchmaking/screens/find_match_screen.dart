import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/matchmaking_provider.dart';
import '../widgets/match_filter_sheet.dart';

class FindMatchScreen extends ConsumerStatefulWidget {
  const FindMatchScreen({super.key});

  @override
  ConsumerState<FindMatchScreen> createState() => _FindMatchScreenState();
}

class _FindMatchScreenState extends ConsumerState<FindMatchScreen> {
  int? _selectedSportId;
  String? _skillFilter;
  double _distanceKm = 50;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportsAsync = ref.watch(sportsListProvider);
    final matchesAsync = _selectedSportId != null
        ? ref.watch(openMatchesProvider(_selectedSportId!))
        : ref.watch(allOpenMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un match'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtres',
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedSportId != null) {
            ref.invalidate(openMatchesProvider(_selectedSportId!));
          } else {
            ref.invalidate(allOpenMatchesProvider);
          }
        },
        child: Column(
          children: [
            // Sport selector chips
            sportsAsync.when(
              data: (sports) => SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Tous'),
                        selected: _selectedSportId == null,
                        onSelected: (_) {
                          setState(() => _selectedSportId = null);
                        },
                      ),
                    ),
                    ...sports.map(
                      (sport) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: sport['icon_url'] != null
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(sport['icon_url']),
                                  backgroundColor: Colors.transparent,
                                )
                              : const Icon(Icons.sports, size: 18),
                          label: Text(
                            sport['display_name'] ?? sport['name'] ?? '',
                          ),
                          selected: _selectedSportId == sport['id'],
                          onSelected: (_) {
                            setState(
                              () => _selectedSportId = sport['id'] as int,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(height: 56),
            ),

            const Divider(height: 1),

            // Match list
            Expanded(
              child: matchesAsync.when(
                data: (matches) {
                  // Apply local skill filter
                  final filtered = _skillFilter != null
                      ? matches
                          .where(
                            (m) =>
                                m['min_skill'] == _skillFilter ||
                                m['min_skill'] == null,
                          )
                          .toList()
                      : matches;

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_handball,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun match trouv\u00e9.',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cr\u00e9e le premier !',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _MatchCard(match: filtered[index]),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur : $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-match'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MatchFilterSheet(
        initialSkill: _skillFilter,
        initialDistance: _distanceKm,
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _skillFilter = result['skill'] as String?;
          _distanceKm = (result['distance'] as double?) ?? 50;
        });
      }
    });
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sport = match['sport'] as Map<String, dynamic>?;
    final participants = match['participants'] as List? ?? [];
    final maxPlayers = match['max_players'];
    final scheduledAt = match['scheduled_at'] != null
        ? DateTime.tryParse(match['scheduled_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/match/${match['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sport icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: sport != null && sport['icon_url'] != null
                      ? Image.network(
                          sport['icon_url'],
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.sports, size: 28),
                        )
                      : Icon(
                          Icons.sports,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Match info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sport?['display_name'] ?? 'Match',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (match['venue_name'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        match['venue_name'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (scheduledAt != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM \u00e0 HH:mm')
                                .format(scheduledAt),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.people,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          maxPlayers != null
                              ? '${participants.length}/$maxPlayers'
                              : '${participants.length}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Skill badge
              if (match['min_skill'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _skillLabel(match['min_skill']),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  String _skillLabel(String? skill) {
    switch (skill) {
      case 'beginner':
        return 'D\u00e9butant';
      case 'intermediate':
        return 'Interm\u00e9diaire';
      case 'advanced':
        return 'Avanc\u00e9';
      case 'expert':
        return 'Expert';
      default:
        return skill ?? '';
    }
  }
}
