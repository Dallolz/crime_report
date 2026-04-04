import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/matchmaking_provider.dart';

class MatchResultScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchResultScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends ConsumerState<MatchResultScreen> {
  final _teamAScoreController = TextEditingController(text: '0');
  final _teamBScoreController = TextEditingController(text: '0');
  bool _isSubmitting = false;
  bool _resultSubmitted = false;

  // Reviews: map of playerId -> review data
  final Map<String, _PlayerReview> _reviews = {};

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void dispose() {
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('R\u00e9sultat du match'),
      ),
      body: matchAsync.when(
        data: (match) => _buildContent(context, theme, match),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> match,
  ) {
    final participants = List<Map<String, dynamic>>.from(
      match['participants'] ?? [],
    );

    // Initialize reviews for other players
    for (final p in participants) {
      final playerId = p['player_id'] as String;
      if (playerId != _currentUserId && !_reviews.containsKey(playerId)) {
        _reviews[playerId] = _PlayerReview();
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!_resultSubmitted) ...[
          // Score entry section
          Text(
            'Score final',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _ScoreInput(
                  label: '\u00c9quipe A',
                  controller: _teamAScoreController,
                  color: Colors.blue,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              Expanded(
                child: _ScoreInput(
                  label: '\u00c9quipe B',
                  controller: _teamBScoreController,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Auto-determined winner
          Builder(
            builder: (context) {
              final a = int.tryParse(_teamAScoreController.text) ?? 0;
              final b = int.tryParse(_teamBScoreController.text) ?? 0;
              String winner;
              if (a > b) {
                winner = '\u00c9quipe A gagne !';
              } else if (b > a) {
                winner = '\u00c9quipe B gagne !';
              } else {
                winner = '\u00c9galit\u00e9';
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  winner,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitResult(context),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirmer le r\u00e9sultat'),
            ),
          ),
        ] else ...[
          // Review section
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'R\u00e9sultat enregistr\u00e9 !',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            '\u00c9value les joueurs',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...participants
              .where((p) => p['player_id'] != _currentUserId)
              .map((p) => _buildReviewCard(theme, p)),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitReviews(context),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Envoyer les reviews'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildReviewCard(ThemeData theme, Map<String, dynamic> participant) {
    final playerId = participant['player_id'] as String;
    final player = participant['player'] as Map<String, dynamic>?;
    final review = _reviews[playerId]!;
    final displayName = player?['display_name'] ??
        player?['username'] ??
        'Joueur';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player name
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: player?['avatar_url'] != null
                      ? NetworkImage(player!['avatar_url'])
                      : null,
                  child: player?['avatar_url'] == null
                      ? Text(
                          (displayName as String).isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Star rating
            Text(
              'Note',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < review.rating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => review.rating = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 8),

            // Fair play toggle
            SwitchListTile(
              title: const Text('Fair-play'),
              value: review.fairPlay,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() => review.fairPlay = value);
              },
            ),

            // Showed up toggle
            SwitchListTile(
              title: const Text('Pr\u00e9sent au match'),
              value: review.showedUp,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() => review.showedUp = value);
              },
            ),
            const SizedBox(height: 8),

            // Comment
            TextField(
              decoration: InputDecoration(
                hintText: 'Commentaire (optionnel)',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              onChanged: (value) => review.comment = value,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitResult(BuildContext context) async {
    final teamAScore = int.tryParse(_teamAScoreController.text) ?? 0;
    final teamBScore = int.tryParse(_teamBScoreController.text) ?? 0;

    String winnerTeam;
    if (teamAScore > teamBScore) {
      winnerTeam = 'A';
    } else if (teamBScore > teamAScore) {
      winnerTeam = 'B';
    } else {
      winnerTeam = 'draw';
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(matchRepositoryProvider);
      await repo.submitResult(
        matchId: widget.matchId,
        reportedBy: _currentUserId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        winnerTeam: winnerTeam,
      );
      if (mounted) {
        setState(() {
          _resultSubmitted = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _submitReviews(BuildContext context) async {
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(matchRepositoryProvider);

      for (final entry in _reviews.entries) {
        await repo.submitReview(
          matchId: widget.matchId,
          reviewerId: _currentUserId,
          reviewedId: entry.key,
          rating: entry.value.rating,
          fairPlay: entry.value.fairPlay,
          showedUp: entry.value.showedUp,
          comment: entry.value.comment?.isNotEmpty == true
              ? entry.value.comment
              : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reviews envoy\u00e9es avec succ\u00e8s !'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }
}

class _ScoreInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;

  const _ScoreInput({
    required this.label,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerReview {
  int rating;
  bool fairPlay;
  bool showedUp;
  String? comment;

  _PlayerReview({
    this.rating = 3,
    this.fairPlay = true,
    this.showedUp = true,
    this.comment,
  });
}
