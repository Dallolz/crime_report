import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/gamification_provider.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final activeChallengesAsync = ref.watch(activeChallengesProvider);
    final userChallengesAsync = ref.watch(userChallengesProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('D\u00e9fis')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeChallengesProvider);
          ref.invalidate(userChallengesProvider(userId));
        },
        child: activeChallengesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (challenges) => userChallengesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (userChallenges) => _ChallengesBody(
              challenges: challenges,
              userChallenges: userChallenges,
              userId: userId,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengesBody extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> challenges;
  final List<Map<String, dynamic>> userChallenges;
  final String userId;

  const _ChallengesBody({
    required this.challenges,
    required this.userChallenges,
    required this.userId,
  });

  @override
  ConsumerState<_ChallengesBody> createState() => _ChallengesBodyState();
}

class _ChallengesBodyState extends ConsumerState<_ChallengesBody> {
  final Set<int> _joiningIds = {};

  /// Returns the user_challenge entry for a given challenge id, or null.
  Map<String, dynamic>? _findUserChallenge(int challengeId) {
    for (final uc in widget.userChallenges) {
      final challenge = uc['challenge'] as Map<String, dynamic>?;
      if (challenge != null && challenge['id'] == challengeId) return uc;
      if (uc['challenge_id'] == challengeId) return uc;
    }
    return null;
  }

  Future<void> _joinChallenge(int challengeId) async {
    setState(() => _joiningIds.add(challengeId));
    try {
      final repo = ref.read(gamificationRepositoryProvider);
      await repo.joinChallenge(widget.userId, challengeId);
      ref.invalidate(userChallengesProvider(widget.userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joiningIds.remove(challengeId));
    }
  }

  IconData _sportIcon(String? sportName) {
    switch (sportName?.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'handball':
        return Icons.sports_handball;
      case 'rugby':
        return Icons.sports_rugby;
      case 'badminton':
        return Icons.sports_tennis;
      case 'running':
        return Icons.directions_run;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun d\u00e9fi actif pour le moment.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez bient\u00f4t !',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'D\u00e9fis actifs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.challenges.map((challenge) {
          final challengeId = challenge['id'] as int;
          final userChallenge = _findUserChallenge(challengeId);
          final joined = userChallenge != null;
          final completed = userChallenge?['completed'] == true;
          final progress = (userChallenge?['progress'] as int?) ?? 0;
          final goal = (challenge['goal'] as int?) ?? 1;
          final xpReward = (challenge['xp_reward'] as int?) ?? 0;
          final sportName = challenge['sport_name'] as String?;
          final endsAt = challenge['ends_at'] != null
              ? DateTime.tryParse(challenge['ends_at'])
              : null;

          return _ChallengeCard(
            title: challenge['title'] as String? ?? 'D\u00e9fi',
            description: challenge['description'] as String? ?? '',
            sportIcon: _sportIcon(sportName),
            sportName: sportName,
            xpReward: xpReward,
            progress: progress,
            goal: goal,
            endsAt: endsAt,
            joined: joined,
            completed: completed,
            joining: _joiningIds.contains(challengeId),
            onJoin: () => _joinChallenge(challengeId),
          );
        }),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData sportIcon;
  final String? sportName;
  final int xpReward;
  final int progress;
  final int goal;
  final DateTime? endsAt;
  final bool joined;
  final bool completed;
  final bool joining;
  final VoidCallback onJoin;

  const _ChallengeCard({
    required this.title,
    required this.description,
    required this.sportIcon,
    this.sportName,
    required this.xpReward,
    required this.progress,
    required this.goal,
    this.endsAt,
    required this.joined,
    required this.completed,
    required this.joining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressFraction = goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: completed
                        ? Colors.green.withValues(alpha: 0.15)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    sportIcon,
                    color: completed
                        ? Colors.green
                        : theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (sportName != null)
                        Text(
                          sportName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                // XP badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$xpReward XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Progress bar (only if joined)
            if (joined) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: completed ? Colors.green : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$progress / $goal',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Footer: deadline + status / join button
            Row(
              children: [
                if (endsAt != null) ...[
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fin le ${DateFormat('dd/MM/yyyy').format(endsAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                const Spacer(),
                if (completed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Compl\u00e9t\u00e9',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (joined)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'En cours',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: joining ? null : onJoin,
                    child: joining
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Rejoindre'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
