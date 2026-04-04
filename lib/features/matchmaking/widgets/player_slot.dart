import 'package:flutter/material.dart';

/// Displays a player slot -- either filled with player info or empty (waiting).
class PlayerSlot extends StatelessWidget {
  /// If non-null, the slot is filled with the participant's data.
  /// Expected keys: player (map with username, display_name, avatar_url), team, status.
  final Map<String, dynamic>? participant;

  const PlayerSlot({super.key, this.participant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (participant == null) {
      return _buildEmptySlot(theme);
    }

    return _buildFilledSlot(theme);
  }

  Widget _buildFilledSlot(ThemeData theme) {
    final player = participant!['player'] as Map<String, dynamic>?;
    final displayName = player?['display_name'] ??
        player?['username'] ??
        'Joueur';
    final avatarUrl = player?['avatar_url'] as String?;
    final team = participant!['team'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: avatarUrl == null
                ? Text(
                    (displayName as String).isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Team badge
          if (team != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: team == 'A'
                    ? Colors.blue.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '\u00c9quipe $team',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: team == 'A' ? Colors.blue : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          // Dashed circle placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.person_add_alt_1,
              size: 20,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'En attente...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
