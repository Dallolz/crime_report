import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'rating_stars.dart';
import 'skill_badge.dart';

class PlayerCard extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String? sportName;
  final int? eloRating;
  final String? skillLevel;
  final double? reputation;
  final String? distance;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.sportName,
    this.eloRating,
    this.skillLevel,
    this.reputation,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl!)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (eloRating != null) ...[
                          Text(
                            '$eloRating ELO',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (skillLevel != null) SkillBadge(level: skillLevel!, fontSize: 10),
                      ],
                    ),
                    if (reputation != null) ...[
                      const SizedBox(height: 4),
                      RatingStars(rating: reputation!, size: 14),
                    ],
                  ],
                ),
              ),
              if (distance != null)
                Text(
                  distance!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
