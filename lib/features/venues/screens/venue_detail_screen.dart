import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/venue_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/constants/sport_config.dart';
import '../../../core/theme/app_theme.dart';

class VenueDetailScreen extends ConsumerWidget {
  final int venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(venueDetailProvider(venueId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du lieu'),
      ),
      body: venueAsync.when(
        loading: () => const LoadingWidget(message: 'Chargement...'),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Impossible de charger ce lieu'),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(venueDetailProvider(venueId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (venue) {
          final name = venue['name'] as String? ?? 'Lieu';
          final address = venue['address'] as String?;
          final rating = (venue['rating'] as num?)?.toDouble() ?? 0.0;
          final reviewCount = venue['review_count'] as int? ?? 0;
          final isVerified = venue['is_verified'] as bool? ?? false;
          final sportIds = (venue['sport_ids'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              [];
          final photos = (venue['photos'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo placeholder or gallery
                if (photos.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            photos[index],
                            height: 200,
                            width: 280,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              width: 280,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  size: 48, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune photo disponible',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Name & verification
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Vérifié',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rating
                if (rating > 0) ...[
                  Row(
                    children: [
                      RatingStars(rating: rating, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '${rating.toStringAsFixed(1)} ($reviewCount avis)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Address
                if (address != null && address.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on,
                                color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adresse',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  address,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Sports
                if (sportIds.isNotEmpty) ...[
                  Text(
                    'Sports disponibles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sportIds.map((id) {
                      final allSports = SportConfig.sports.values.toList();
                      final sportIndex = id - 1;
                      if (sportIndex >= 0 &&
                          sportIndex < allSports.length) {
                        final config = allSports[sportIndex];
                        return Chip(
                          avatar: Icon(config.icon,
                              size: 18, color: config.color),
                          label: Text(config.displayName),
                          backgroundColor:
                              config.color.withOpacity(0.1),
                          side: BorderSide(
                              color: config.color.withOpacity(0.3)),
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Navigate button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Navigation non disponible pour le moment'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text(
                      "S'y rendre",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Share button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Partage non disponible pour le moment'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text(
                      'Partager ce lieu',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
