import 'package:freezed_annotation/freezed_annotation.dart';

import 'sport.dart';

part 'player_sport.freezed.dart';
part 'player_sport.g.dart';

@freezed
class PlayerSport with _$PlayerSport {
  const factory PlayerSport({
    required int id,
    required String playerId,
    required int sportId,
    @Default(1000) int eloRating,
    @Default('beginner') String skillLevel,
    @Default(0) int matchesPlayed,
    @Default(0) int wins,
    @Default(5.0) double reputationScore,
    @Default(0) int xp,
    Sport? sport,
  }) = _PlayerSport;

  factory PlayerSport.fromJson(Map<String, dynamic> json) => _$PlayerSportFromJson(json);
}
