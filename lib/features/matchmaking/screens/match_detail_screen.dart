import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/matchmaking_provider.dart';
import '../widgets/player_slot.dart';
import '../widgets/team_builder.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _actionLoading = false;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('D\u00e9tails du match'),
      ),
      body: matchAsync.when(
        data: (match) => _buildContent(context, theme, match),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur : $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> match,
  ) {
    final sport = match['sport'] as Map<String, dynamic>?;
    final creator = match['creator'] as Map<String, dynamic>?;
    final participants = List<Map<String, dynamic>>.from(
      match['participants'] ?? [],
    );
    final status = match['status'] as String? ?? 'open';
    final isCreator = match['creator_id'] == _currentUserId;
    final isParticipant = participants.any(
      (p) => p['player_id'] == _currentUserId,
    );
    final maxPlayers = match['max_players'] as int?;
    final scheduledAt = match['scheduled_at'] != null
        ? DateTime.tryParse(match['scheduled_at'])
        : null;
    final isTeamSport =
        sport != null && (sport['match_format'] == 'team');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(matchDetailProvider(widget.matchId));
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header: sport icon + name + status
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: sport != null && sport['icon_url'] != null
                      ? Image.network(
                          sport['icon_url'],
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.sports, size: 32),
                        )
                      : Icon(
                          Icons.sports,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sport?['display_name'] ?? 'Match',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (creator != null)
                      Text(
                        'par ${creator['display_name'] ?? creator['username'] ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 24),

          // Info rows
          if (match['venue_name'] != null)
            _InfoRow(
              icon: Icons.location_on,
              label: match['venue_name'],
            ),
          if (match['address'] != null)
            _InfoRow(
              icon: Icons.map,
              label: match['address'],
            ),
          if (scheduledAt != null)
            _InfoRow(
              icon: Icons.calendar_today,
              label: DateFormat('EEEE dd MMMM yyyy \u00e0 HH:mm', 'fr')
                  .format(scheduledAt),
            ),
          if (match['duration_min'] != null)
            _InfoRow(
              icon: Icons.timer,
              label: '${match['duration_min']} minutes',
            ),
          _InfoRow(
            icon: Icons.people,
            label: maxPlayers != null
                ? '${participants.length}/$maxPlayers joueurs'
                : '${participants.length} joueurs',
          ),
          if (match['min_skill'] != null || match['max_skill'] != null)
            _InfoRow(
              icon: Icons.trending_up,
              label: _skillRangeLabel(
                match['min_skill'],
                match['max_skill'],
              ),
            ),

          // Description
          if (match['description'] != null &&
              (match['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Description',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match['description'],
              style: theme.textTheme.bodyMedium,
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Players section
          Text(
            'Joueurs',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (isTeamSport)
            TeamBuilder(
              participants: participants,
              maxPlayers: maxPlayers,
            )
          else
            _buildPlayerList(theme, participants, maxPlayers),

          const SizedBox(height: 32),

          // Action buttons
          _buildActions(
            context,
            theme,
            status: status,
            isCreator: isCreator,
            isParticipant: isParticipant,
            participantCount: participants.length,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(
    ThemeData theme,
    List<Map<String, dynamic>> participants,
    int? maxPlayers,
  ) {
    final totalSlots = maxPlayers ?? participants.length;
    return Column(
      children: [
        ...participants.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PlayerSlot(participant: p),
          ),
        ),
        // Empty slots
        for (var i = participants.length; i < totalSlots; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: PlayerSlot(),
          ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    ThemeData theme, {
    required String status,
    required bool isCreator,
    required bool isParticipant,
    required int participantCount,
  }) {
    if (_actionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final buttons = <Widget>[];

    // Join / Leave buttons
    if ((status == 'open' || status == 'full') && !isParticipant) {
      if (status == 'open') {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Rejoindre'),
              onPressed: () => _joinMatch(context),
            ),
          ),
        );
      }
    } else if (isParticipant && !isCreator && status == 'open') {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Quitter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: () => _leaveMatch(context),
          ),
        ),
      );
    }

    // Creator actions
    if (isCreator) {
      if ((status == 'open' || status == 'full') && participantCount >= 2) {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('D\u00e9marrer'),
              onPressed: () => _startMatch(context),
            ),
          ),
        );
      }

      if (status == 'in_progress') {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flag),
              label: const Text('Terminer & R\u00e9sultat'),
              onPressed: () =>
                  context.push('/match/${widget.matchId}/result'),
            ),
          ),
        );
      }
    }

    // Lobby button
    if (status == 'open' || status == 'full') {
      if (isParticipant) {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.meeting_room),
              label: const Text('Salon d\'attente'),
              onPressed: () =>
                  context.push('/match/${widget.matchId}/lobby'),
            ),
          ),
        );
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      children: buttons
          .expand((btn) => [btn, const SizedBox(height: 12)])
          .toList()
        ..removeLast(),
    );
  }

  Future<void> _joinMatch(BuildContext context) async {
    setState(() => _actionLoading = true);
    try {
      final repo = ref.read(matchRepositoryProvider);
      await repo.joinMatch(
        matchId: widget.matchId,
        playerId: _currentUserId,
      );
      ref.invalidate(matchDetailProvider(widget.matchId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _leaveMatch(BuildContext context) async {
    setState(() => _actionLoading = true);
    try {
      final repo = ref.read(matchRepositoryProvider);
      await repo.leaveMatch(
        matchId: widget.matchId,
        playerId: _currentUserId,
      );
      ref.invalidate(matchDetailProvider(widget.matchId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _startMatch(BuildContext context) async {
    setState(() => _actionLoading = true);
    try {
      final repo = ref.read(matchRepositoryProvider);
      await repo.updateMatchStatus(
        matchId: widget.matchId,
        status: 'in_progress',
      );
      ref.invalidate(matchDetailProvider(widget.matchId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _skillRangeLabel(String? min, String? max) {
    final labels = {
      'beginner': 'D\u00e9butant',
      'intermediate': 'Interm\u00e9diaire',
      'advanced': 'Avanc\u00e9',
      'expert': 'Expert',
    };
    final minLabel = labels[min];
    final maxLabel = labels[max];
    if (minLabel != null && maxLabel != null) {
      return '$minLabel \u2192 $maxLabel';
    }
    return minLabel ?? maxLabel ?? '';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open' => ('Ouvert', Colors.green),
      'full' => ('Complet', Colors.orange),
      'in_progress' => ('En cours', Colors.blue),
      'completed' => ('Termin\u00e9', Colors.grey),
      'cancelled' => ('Annul\u00e9', Colors.red),
      _ => (status, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
