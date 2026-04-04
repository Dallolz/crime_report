import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/venue_provider.dart';
import '../../sports/providers/sport_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/constants/sport_config.dart';

class VenuesMapScreen extends ConsumerStatefulWidget {
  const VenuesMapScreen({super.key});

  @override
  ConsumerState<VenuesMapScreen> createState() => _VenuesMapScreenState();
}

class _VenuesMapScreenState extends ConsumerState<VenuesMapScreen> {
  int? _selectedSportId;

  @override
  Widget build(BuildContext context) {
    final sportsAsync = ref.watch(allSportsProvider);
    final venuesAsync = ref.watch(venuesProvider(_selectedSportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieux'),
      ),
      body: Column(
        children: [
          // Sport filter chips
          sportsAsync.when(
            loading: () => const SizedBox(height: 56),
            error: (_, __) => const SizedBox.shrink(),
            data: (sports) => SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: sports.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChip(
                      selected: _selectedSportId == null,
                      label: const Text('Tous'),
                      onSelected: (_) {
                        setState(() => _selectedSportId = null);
                      },
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      showCheckmark: false,
                    );
                  }
                  final sport = sports[index - 1];
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
            ),
          ),
          const Divider(height: 1),

          // Venue cards list
          Expanded(
            child: venuesAsync.when(
              loading: () =>
                  const LoadingWidget(message: 'Chargement des lieux...'),
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
                      onPressed: () => ref.invalidate(
                          venuesProvider(_selectedSportId)),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (venues) {
                if (venues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun lieu trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Essayez un autre filtre de sport',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(venuesProvider(_selectedSportId));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: venues.length,
                    itemBuilder: (context, index) {
                      final venue = venues[index];
                      return _VenueCard(
                        venue: venue,
                        onTap: () {
                          final venueId = venue['id'];
                          if (venueId != null) {
                            context.push('/venue/$venueId');
                          }
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

class _VenueCard extends StatelessWidget {
  final Map<String, dynamic> venue;
  final VoidCallback onTap;

  const _VenueCard({required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = venue['name'] as String? ?? 'Lieu';
    final address = venue['address'] as String?;
    final rating = (venue['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = venue['review_count'] as int? ?? 0;
    final sportIds = (venue['sport_ids'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name & rating
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (rating > 0) ...[
                    RatingStars(rating: rating, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '($reviewCount)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),

              // Address
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Sport icons
              if (sportIds.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: sportIds.map((id) {
                    // Attempt to map sport IDs to config names
                    final allSports = SportConfig.sports.values.toList();
                    final sportIndex = id - 1;
                    if (sportIndex >= 0 && sportIndex < allSports.length) {
                      final config = allSports[sportIndex];
                      return Chip(
                        avatar: Icon(config.icon,
                            size: 16, color: config.color),
                        label: Text(
                          config.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
