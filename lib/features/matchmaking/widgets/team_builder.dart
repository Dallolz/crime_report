import 'package:flutter/material.dart';

import 'player_slot.dart';

/// Displays two teams (A and B) side by side with their player slots.
class TeamBuilder extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final int? maxPlayers;

  const TeamBuilder({
    super.key,
    required this.participants,
    this.maxPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final teamA =
        participants.where((p) => p['team'] == 'A').toList();
    final teamB =
        participants.where((p) => p['team'] == 'B').toList();
    final unassigned = participants
        .where((p) => p['team'] != 'A' && p['team'] != 'B')
        .toList();

    // Calculate slots per team
    final slotsPerTeam =
        maxPlayers != null ? (maxPlayers! / 2).ceil() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two-column layout for teams
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team A
            Expanded(
              child: _TeamColumn(
                teamName: '\u00c9quipe A',
                color: Colors.blue,
                players: teamA,
                totalSlots: slotsPerTeam,
              ),
            ),
            const SizedBox(width: 12),
            // Team B
            Expanded(
              child: _TeamColumn(
                teamName: '\u00c9quipe B',
                color: Colors.red,
                players: teamB,
                totalSlots: slotsPerTeam,
              ),
            ),
          ],
        ),

        // Unassigned players
        if (unassigned.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Non assign\u00e9s',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          ...unassigned.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlayerSlot(participant: p),
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String teamName;
  final Color color;
  final List<Map<String, dynamic>> players;
  final int? totalSlots;

  const _TeamColumn({
    required this.teamName,
    required this.color,
    required this.players,
    this.totalSlots,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotCount = totalSlots ?? players.length;

    return Column(
      children: [
        // Team header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            teamName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Player slots
        ...List.generate(slotCount, (index) {
          final participant =
              index < players.length ? players[index] : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _CompactPlayerSlot(
              participant: participant,
              color: color,
            ),
          );
        }),
      ],
    );
  }
}

/// A compact version of PlayerSlot for the team columns.
class _CompactPlayerSlot extends StatelessWidget {
  final Map<String, dynamic>? participant;
  final Color color;

  const _CompactPlayerSlot({
    this.participant,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (participant == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Icon(
                Icons.person_add_alt_1,
                size: 14,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Libre',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final player = participant!['player'] as Map<String, dynamic>?;
    final displayName = player?['display_name'] ??
        player?['username'] ??
        'Joueur';
    final avatarUrl = player?['avatar_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: color.withOpacity(0.2),
            child: avatarUrl == null
                ? Text(
                    (displayName as String).isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
