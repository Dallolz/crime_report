import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_result.freezed.dart';
part 'match_result.g.dart';

@freezed
class MatchResult with _$MatchResult {
  const factory MatchResult({
    required int id,
    required String matchId,
    int? teamAScore,
    int? teamBScore,
    String? winnerTeam,
    String? reportedBy,
    @Default([]) List<String> confirmedBy,
    DateTime? createdAt,
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);
}
