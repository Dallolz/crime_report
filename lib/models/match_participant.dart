import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

part 'match_participant.freezed.dart';
part 'match_participant.g.dart';

@freezed
class MatchParticipant with _$MatchParticipant {
  const factory MatchParticipant({
    required int id,
    required String matchId,
    required String playerId,
    String? team,
    @Default('joined') String status,
    DateTime? joinedAt,
    Profile? player,
  }) = _MatchParticipant;

  factory MatchParticipant.fromJson(Map<String, dynamic> json) => _$MatchParticipantFromJson(json);
}
