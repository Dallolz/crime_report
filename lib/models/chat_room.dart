import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

@freezed
class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String id,
    String? name,
    required String type,
    int? sportId,
    String? matchId,
    String? city,
    DateTime? createdAt,
    @Default([]) List<ChatMember> members,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);
}

@freezed
class ChatMember with _$ChatMember {
  const factory ChatMember({
    required String roomId,
    required String userId,
    DateTime? joinedAt,
    Profile? user,
  }) = _ChatMember;

  factory ChatMember.fromJson(Map<String, dynamic> json) => _$ChatMemberFromJson(json);
}
