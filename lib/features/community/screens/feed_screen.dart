import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/feed_provider.dart';
import '../../../core/widgets/loading_widget.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tout'),
            Tab(text: 'Abonnements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FeedList(isGlobal: true),
          _FeedList(isGlobal: false),
        ],
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  final bool isGlobal;

  const _FeedList({required this.isGlobal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync =
        isGlobal ? ref.watch(globalFeedProvider) : ref.watch(followingFeedProvider);

    return feedAsync.when(
      loading: () => const LoadingWidget(message: 'Chargement du fil...'),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                if (isGlobal) {
                  ref.invalidate(globalFeedProvider);
                } else {
                  ref.invalidate(followingFeedProvider);
                }
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGlobal ? Icons.feed_outlined : Icons.group_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isGlobal
                      ? 'Aucune activité pour le moment'
                      : 'Abonnez-vous à des joueurs\npour voir leur activité ici',
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
            if (isGlobal) {
              ref.invalidate(globalFeedProvider);
            } else {
              ref.invalidate(followingFeedProvider);
            }
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final actor = item['actor'] as Map<String, dynamic>?;

              return _FeedItem(
                displayName: actor?['display_name'] ?? 'Joueur',
                avatarUrl: actor?['avatar_url'] as String?,
                actionType: item['action_type'] as String? ?? '',
                metadata: item['metadata'] as Map<String, dynamic>? ?? {},
                createdAt: item['created_at'] != null
                    ? DateTime.tryParse(item['created_at'].toString())
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _FeedItem extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String actionType;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const _FeedItem({
    required this.displayName,
    this.avatarUrl,
    required this.actionType,
    required this.metadata,
    this.createdAt,
  });

  String _actionDescription() {
    switch (actionType) {
      case 'match_created':
        return 'a créé un match';
      case 'match_joined':
        return 'a rejoint un match';
      case 'match_completed':
        return 'a terminé un match';
      case 'match_won':
        return 'a remporté un match';
      case 'review_posted':
        return 'a laissé un avis';
      case 'badge_earned':
        final badgeName = metadata['badge_name'] ?? 'un badge';
        return 'a obtenu le badge "$badgeName"';
      case 'level_up':
        final level = metadata['level'] ?? '';
        return 'est passé au niveau $level';
      case 'follow':
        final targetName = metadata['target_name'] ?? 'un joueur';
        return 'suit maintenant $targetName';
      case 'sport_added':
        final sportName = metadata['sport_name'] ?? 'un sport';
        return 'pratique maintenant $sportName';
      default:
        return 'a effectué une action';
    }
  }

  IconData _actionIcon() {
    switch (actionType) {
      case 'match_created':
        return Icons.add_circle_outline;
      case 'match_joined':
        return Icons.group_add;
      case 'match_completed':
        return Icons.check_circle_outline;
      case 'match_won':
        return Icons.emoji_events;
      case 'review_posted':
        return Icons.star_outline;
      case 'badge_earned':
        return Icons.military_tech;
      case 'level_up':
        return Icons.trending_up;
      case 'follow':
        return Icons.person_add;
      case 'sport_added':
        return Icons.sports;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${_actionDescription()}'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (createdAt != null)
                  Text(
                    timeago.format(createdAt!, locale: 'fr'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            _actionIcon(),
            size: 20,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}
