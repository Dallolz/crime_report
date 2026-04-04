import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/gamification_provider.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allBadgesProvider);
          ref.invalidate(userBadgesProvider(userId));
        },
        child: allBadgesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (allBadges) => userBadgesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (userBadges) =>
                _BadgesBody(allBadges: allBadges, userBadges: userBadges),
          ),
        ),
      ),
    );
  }
}

class _BadgesBody extends StatelessWidget {
  final List<Map<String, dynamic>> allBadges;
  final List<Map<String, dynamic>> userBadges;

  const _BadgesBody({required this.allBadges, required this.userBadges});

  /// Returns the user_badge entry for a given badge id, or null.
  Map<String, dynamic>? _findUserBadge(int badgeId) {
    for (final ub in userBadges) {
      final badge = ub['badge'] as Map<String, dynamic>?;
      if (badge != null && badge['id'] == badgeId) return ub;
      if (ub['badge_id'] == badgeId) return ub;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earnedBadges = userBadges.where((ub) {
      final badge = ub['badge'] as Map<String, dynamic>?;
      return badge != null;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Earned badges ---
        Text(
          'Mes badges',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (earnedBadges.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Aucun badge obtenu pour le moment.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: earnedBadges.length,
            itemBuilder: (context, index) {
              final ub = earnedBadges[index];
              final badge = ub['badge'] as Map<String, dynamic>;
              final earnedAt = ub['earned_at'] != null
                  ? DateTime.tryParse(ub['earned_at'])
                  : null;
              return _BadgeCard(
                badge: badge,
                earned: true,
                earnedAt: earnedAt,
              );
            },
          ),

        const SizedBox(height: 32),

        // --- All badges ---
        Text(
          'Tous les badges',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: allBadges.length,
          itemBuilder: (context, index) {
            final badge = allBadges[index];
            final userBadge = _findUserBadge(badge['id'] as int);
            final earned = userBadge != null;
            final earnedAt = earned && userBadge['earned_at'] != null
                ? DateTime.tryParse(userBadge['earned_at'])
                : null;
            return _BadgeCard(
              badge: badge,
              earned: earned,
              earnedAt: earnedAt,
            );
          },
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;
  final bool earned;
  final DateTime? earnedAt;

  const _BadgeCard({
    required this.badge,
    required this.earned,
    this.earnedAt,
  });

  IconData _resolveIcon(String? iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'star':
        return Icons.star;
      case 'whatshot':
        return Icons.whatshot;
      case 'groups':
        return Icons.groups;
      case 'military_tech':
        return Icons.military_tech;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'workspace_premium':
        return Icons.workspace_premium;
      default:
        return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconName = badge['icon'] as String?;
    final name = badge['name'] as String? ?? '';
    final description = badge['description'] as String? ?? '';

    return Card(
      elevation: earned ? 2 : 0,
      color: earned ? null : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBadgeDetail(context, name, description),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _resolveIcon(iconName),
                size: 36,
                color: earned
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: earned ? null : theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                earned && earnedAt != null
                    ? DateFormat('dd/MM/yyyy').format(earnedAt!)
                    : 'Non d\u00e9bloqu\u00e9',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: earned
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, String name, String description) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
