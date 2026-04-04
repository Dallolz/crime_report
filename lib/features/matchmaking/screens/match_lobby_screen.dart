import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/matchmaking_provider.dart';
import '../widgets/player_slot.dart';

class MatchLobbyScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchLobbyScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends ConsumerState<MatchLobbyScreen>
    with SingleTickerProviderStateMixin {
  RealtimeChannel? _channel;
  final _messageController = TextEditingController();
  final _messages = <_ChatMessage>[];
  final _scrollController = ScrollController();
  late AnimationController _shimmerController;
  bool _isReady = false;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _subscribeToMatch();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _subscribeToMatch() {
    final repo = ref.read(matchRepositoryProvider);
    _channel = repo.subscribeToMatch(widget.matchId, (_) {
      // Refresh match data when participants change
      ref.invalidate(matchDetailProvider(widget.matchId));
    });

    // Also subscribe to broadcast for chat messages
    _channel
        ?.onBroadcast(
          event: 'chat',
          callback: (payload) {
            if (mounted) {
              setState(() {
                _messages.add(_ChatMessage(
                  userId: payload['user_id'] as String? ?? '',
                  username: payload['username'] as String? ?? '',
                  text: payload['text'] as String? ?? '',
                  timestamp: DateTime.now(),
                ));
              });
              _scrollToBottom();
            }
          },
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon d\'attente'),
        actions: [
          matchAsync.whenOrNull(
                data: (match) {
                  final isCreator = match['creator_id'] == _currentUserId;
                  if (!isCreator) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'D\u00e9marrer le match',
                    onPressed: () => _startMatch(context),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: matchAsync.when(
        data: (match) => _buildLobby(context, theme, match),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
    );
  }

  Widget _buildLobby(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> match,
  ) {
    final sport = match['sport'] as Map<String, dynamic>?;
    final participants = List<Map<String, dynamic>>.from(
      match['participants'] ?? [],
    );
    final maxPlayers = match['max_players'] as int? ?? 10;
    final status = match['status'] as String? ?? 'open';

    // If match is in_progress, navigate to detail
    if (status == 'in_progress') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement('/match/${widget.matchId}');
        }
      });
    }

    return Column(
      children: [
        // Match info header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          ),
          child: Column(
            children: [
              Text(
                sport?['display_name'] ?? 'Match',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                match['venue_name'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              // Shimmer "waiting" indicator
              FadeTransition(
                opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _shimmerController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Text(
                  'En attente de joueurs...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Player slots
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Joueurs (${participants.length}/$maxPlayers)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Filled slots
              ...participants.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PlayerSlot(participant: p),
                ),
              ),
              // Empty slots
              for (var i = participants.length; i < maxPlayers; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: PlayerSlot(),
                ),

              const SizedBox(height: 24),

              // Ready button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    _isReady ? Icons.check_circle : Icons.check_circle_outline,
                  ),
                  label: Text(_isReady ? 'Pr\u00eat !' : 'Je suis pr\u00eat !'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isReady ? Colors.green : theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() => _isReady = !_isReady);
                    // Broadcast ready state
                    _channel?.sendBroadcastMessage(
                      event: 'ready',
                      payload: {
                        'user_id': _currentUserId,
                        'is_ready': _isReady,
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Chat section
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            children: [
              // Messages
              SizedBox(
                height: 120,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.userId == _currentUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg.username,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  Text(
                                    msg.text,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: '\u00c9crire un message...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: theme.colorScheme.primary,
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] as String? ?? 'Joueur';

    _channel?.sendBroadcastMessage(
      event: 'chat',
      payload: {
        'user_id': _currentUserId,
        'username': username,
        'text': text,
      },
    );

    // Add locally too
    setState(() {
      _messages.add(_ChatMessage(
        userId: _currentUserId,
        username: username,
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _startMatch(BuildContext context) async {
    try {
      final repo = ref.read(matchRepositoryProvider);
      await repo.updateMatchStatus(
        matchId: widget.matchId,
        status: 'in_progress',
      );
      if (mounted) {
        context.pushReplacement('/match/${widget.matchId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }
}

class _ChatMessage {
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;

  _ChatMessage({
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
  });
}
