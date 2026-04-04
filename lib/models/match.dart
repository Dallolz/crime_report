import 'package:freezed_annotation/freezed_annotation.dart';

import 'sport.dart';
import 'profile.dart';
import 'match_participant.dart';

part 'match.freezed.dart';
part 'match.g.dart';

@freezed
class SportMatch with _$SportMatch {
  const factory SportMatch({
    required String id,
    required int sportId,
    required String creatorId,
    @Default('open') String status,
    String? matchType,
    double? latitude,
    double? longitude,
    String? venueName,
    String? address,
    DateTime? scheduledAt,
    int? durationMin,
    int? maxPlayers,
    String? minSkill,
    String? maxSkill,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    Sport? sport,
    Profile? creator,
    @Default([]) List<MatchParticipant> participants,
  }) = _SportMatch;

  factory SportMatch.fromJson(Map<String, dynamic> json) => _$SportMatchFromJson(json);
}
