import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required int id,
    required String roomId,
    required String senderId,
    required String content,
    DateTime? createdAt,
    Profile? sender,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
