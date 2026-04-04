import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/skill_badge.dart';
import '../../../core/widgets/rating_stars.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final targetUserId = userId ?? currentUser?.id ?? '';
    final isOwnProfile = targetUserId == currentUser?.id;

    final profileAsync = ref.watch(userProfileProvider(targetUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/profile/edit'),
            ),
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (profile) => _buildProfile(context, ref, profile, isOwnProfile, targetUserId),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> profile,
    bool isOwnProfile,
    String targetUserId,
  ) {
    final playerSports = List<Map<String, dynamic>>.from(profile['player_sports'] ?? []);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider(targetUserId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Info
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? Text(
                          (profile['display_name'] ?? profile['username'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 28),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['display_name'] ?? profile['username'] ?? 'Joueur',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '@${profile['username'] ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      if (profile['city'] != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              profile['city'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (profile['bio'] != null && profile['bio'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(profile['bio']),
            ],

            // XP + Streak
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  icon: Icons.star,
                  label: '${profile['xp_total'] ?? 0} XP',
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.local_fire_department,
                  label: '${profile['streak_days'] ?? 0} jours',
                  color: Colors.deepOrange,
                ),
              ],
            ),

            // Follow button
            if (!isOwnProfile) ...[
              const SizedBox(height: 16),
              _FollowButton(targetUserId: targetUserId),
            ],

            // Sports
            const SizedBox(height: 24),
            Text(
              'Sports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (playerSports.isEmpty)
              const Text('Aucun sport sélectionné', style: TextStyle(color: Colors.grey))
            else
              ...playerSports.map((ps) => _SportCard(
                    playerSport: ps,
                    onTap: () => context.push(
                      '/profile/$targetUserId/sport/${ps['sport_id']}',
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final String targetUserId;

  const _FollowButton({required this.targetUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final isFollowingAsync = ref.watch(isFollowingProvider(
      (currentUserId: currentUser.id, targetUserId: targetUserId),
    ));

    return isFollowingAsync.when(
      loading: () => const SizedBox(height: 36, width: 120, child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (isFollowing) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final repo = ref.read(profileRepositoryProvider);
            if (isFollowing) {
              await repo.unfollowUser(currentUser.id, targetUserId);
            } else {
              await repo.followUser(currentUser.id, targetUserId);
            }
            ref.invalidate(isFollowingProvider(
              (currentUserId: currentUser.id, targetUserId: targetUserId),
            ));
          },
          icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
          label: Text(isFollowing ? 'Ne plus suivre' : 'Suivre'),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  final Map<String, dynamic> playerSport;
  final VoidCallback onTap;

  const _SportCard({required this.playerSport, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sport = playerSport['sport'] as Map<String, dynamic>?;
    final sportName = sport?['display_name'] ?? 'Sport';
    final elo = playerSport['elo_rating'] ?? 1000;
    final skillLevel = playerSport['skill_level'] ?? 'beginner';
    final matchesPlayed = playerSport['matches_played'] ?? 0;
    final wins = playerSport['wins'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(sportName[0], style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(sportName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            SkillBadge(level: skillLevel),
            const SizedBox(width: 8),
            Text('ELO $elo'),
            const SizedBox(width: 8),
            Text('$wins/$matchesPlayed V', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
