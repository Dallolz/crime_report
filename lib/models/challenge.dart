import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required int id,
    required String title,
    String? description,
    int? sportId,
    @Default(50) int xpReward,
    @Default({}) Map<String, dynamic> conditionJson,
    DateTime? startsAt,
    DateTime? endsAt,
    @Default(true) bool isActive,
  }) = _Challenge;

  factory Challenge.fromJson(Map<String, dynamic> json) => _$ChallengeFromJson(json);
}

@freezed
class UserChallenge with _$UserChallenge {
  const factory UserChallenge({
    required String userId,
    required int challengeId,
    @Default(0) int progress,
    @Default(false) bool completed,
    DateTime? completedAt,
    Challenge? challenge,
  }) = _UserChallenge;

  factory UserChallenge.fromJson(Map<String, dynamic> json) => _$UserChallengeFromJson(json);
}
