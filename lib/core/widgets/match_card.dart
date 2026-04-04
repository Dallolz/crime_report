import 'package:flutter/material.dart';
import '../constants/sport_config.dart';
import 'sport_icon.dart';
import 'skill_badge.dart';

class MatchCard extends StatelessWidget {
  final String sportName;
  final String title;
  final String location;
  final String date;
  final int currentPlayers;
  final int maxPlayers;
  final String? skillLevel;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.sportName,
    required this.title,
    required this.location,
    required this.date,
    required this.currentPlayers,
    required this.maxPlayers,
    this.skillLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = SportConfig.getSport(sportName);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SportIcon(sportName: sportName, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const Spacer(),
                        Icon(Icons.people, size: 14, color: config?.color ?? Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$currentPlayers/$maxPlayers',
                          style: TextStyle(
                            color: config?.color ?? Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (skillLevel != null) ...[
                      const SizedBox(height: 8),
                      SkillBadge(level: skillLevel!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
