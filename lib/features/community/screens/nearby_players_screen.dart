import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/feed_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/player_card.dart';

class NearbyPlayersScreen extends ConsumerStatefulWidget {
  const NearbyPlayersScreen({super.key});

  @override
  ConsumerState<NearbyPlayersScreen> createState() =>
      _NearbyPlayersScreenState();
}

class _NearbyPlayersScreenState extends ConsumerState<NearbyPlayersScreen> {
  final _searchController = TextEditingController();
  String? _searchCity;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _searchCity = value.trim().isEmpty ? null : value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(nearbyPlayersProvider(_searchCity));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Joueurs à proximité'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par ville...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: _onSearch,
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) _onSearch('');
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: playersAsync.when(
              loading: () =>
                  const LoadingWidget(message: 'Recherche de joueurs...'),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Erreur de chargement'),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.invalidate(nearbyPlayersProvider(_searchCity)),
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
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchCity != null
                              ? 'Aucun joueur trouvé pour "$_searchCity"'
                              : 'Aucun joueur à proximité',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(nearbyPlayersProvider(_searchCity));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final playerSports = player['player_sports']
                              as List<dynamic>? ??
                          [];

                      final topSport = playerSports.isNotEmpty
                          ? playerSports.first as Map<String, dynamic>
                          : null;
                      final sportData =
                          topSport?['sport'] as Map<String, dynamic>?;

                      return PlayerCard(
                        displayName:
                            player['display_name'] as String? ?? 'Joueur',
                        avatarUrl: player['avatar_url'] as String?,
                        sportName: sportData?['display_name'] as String?,
                        eloRating: topSport?['elo_rating'] as int?,
                        skillLevel: topSport?['skill_level'] as String?,
                        distance: player['city'] as String?,
                        onTap: () {
                          context.push('/profile/${player['id']}');
                        },
                      );
                    },
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
