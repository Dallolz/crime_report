import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/chat_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/theme/app_theme.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatDialog(context, ref),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: roomsAsync.when(
        loading: () => const LoadingWidget(message: 'Chargement des conversations...'),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Erreur de chargement'),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(chatRoomsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez une discussion avec un joueur !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatRoomsProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final roomData = rooms[index];
                final room =
                    roomData['room'] as Map<String, dynamic>? ?? roomData;
                final members =
                    room['members'] as List<dynamic>? ?? [];
                final roomId = room['id']?.toString() ?? '';
                final roomName = room['name'] as String? ?? 'Conversation';
                final roomType = room['type'] as String? ?? 'direct';
                final createdAt = room['created_at'] != null
                    ? DateTime.tryParse(room['created_at'].toString())
                    : null;

                return _ChatRoomTile(
                  roomId: roomId,
                  roomName: roomName,
                  roomType: roomType,
                  memberCount: members.length,
                  lastActivity: createdAt,
                  onTap: () {
                    context.push('/chat/$roomId');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateChatDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final user = ref.read(currentUserProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du groupe',
                hintText: 'Ex: Football du dimanche',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty || user == null) return;

              final repo = ref.read(chatRepositoryProvider);
              try {
                await repo.createRoom(
                  name: name,
                  type: 'group',
                  memberIds: [user.id],
                );
                ref.invalidate(chatRoomsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Erreur : ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final String roomId;
  final String roomName;
  final String roomType;
  final int memberCount;
  final DateTime? lastActivity;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.roomId,
    required this.roomName,
    required this.roomType,
    required this.memberCount,
    this.lastActivity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = roomType == 'group';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
        child: Icon(
          isGroup ? Icons.group : Icons.person,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(
        roomName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isGroup ? '$memberCount membres' : 'Discussion directe',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
      trailing: lastActivity != null
          ? Text(
              timeago.format(lastActivity!, locale: 'fr'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            )
          : null,
    );
  }
}
