import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/constants/sport_config.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myProfileProvider);
            ref.invalidate(upcomingMatchesProvider);
            ref.invalidate(nearbyMatchesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                profileAsync.when(
                  loading: () => const SizedBox(height: 60),
                  error: (_, __) => const SizedBox(height: 60),
                  data: (profile) => Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: profile?['avatar_url'] != null
                            ? NetworkImage(profile!['avatar_url'])
                            : null,
                        child: profile?['avatar_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salut ${profile?['display_name'] ?? 'Joueur'} !',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Prêt à jouer ?',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick match button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/matchmaking'),
                    icon: const Icon(Icons.flash_on),
                    label: const Text(
                      'Trouver un match',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upcoming matches
                _SectionHeader(
                  title: 'Mes prochains matchs',
                  onSeeAll: () => context.go('/matchmaking'),
                ),
                const SizedBox(height: 8),
                _UpcomingMatchesList(),
                const SizedBox(height: 24),

                // Nearby matches
                _SectionHeader(
                  title: 'Matchs à proximité',
                  onSeeAll: () => context.go('/matchmaking'),
                ),
                const SizedBox(height: 8),
                _NearbyMatchesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('Voir tout'),
        ),
      ],
    );
  }
}

class _UpcomingMatchesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);

    return matchesAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (matches) {
        if (matches.isEmpty) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucun match prévu\nRejoins ou crée un match !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final m = matches[i];
              final sport = m['sport'] as Map<String, dynamic>?;
              final config = SportConfig.getConfig(sport?['name'] ?? '');

              return GestureDetector(
                onTap: () => context.push('/matchmaking/${m['id']}'),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: config.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(config.icon, color: config.color, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            sport?['display_name'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold, color: config.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['venue_name'] ?? 'Lieu TBD',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (m['scheduled_at'] != null)
                        Text(
                          timeago.format(DateTime.parse(m['scheduled_at']), locale: 'fr'),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NearbyMatchesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(nearbyMatchesProvider);

    return matchesAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (matches) {
        if (matches.isEmpty) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucun match à proximité',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, i) {
            final m = matches[i];
            final sport = m['sport'] as Map<String, dynamic>?;
            final config = SportConfig.getConfig(sport?['name'] ?? '');
            final creator = m['creator'] as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => context.push('/matchmaking/${m['id']}'),
                leading: CircleAvatar(
                  backgroundColor: config.color.withOpacity(0.2),
                  child: Icon(config.icon, color: config.color),
                ),
                title: Text(
                  m['venue_name'] ?? sport?['display_name'] ?? 'Match',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Par ${creator?['display_name'] ?? 'Inconnu'} | ${m['address'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Chip(
                  label: Text(
                    m['status'] ?? 'open',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: config.color.withOpacity(0.1),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
