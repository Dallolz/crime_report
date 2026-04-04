import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

part 'match_review.freezed.dart';
part 'match_review.g.dart';

@freezed
class MatchReview with _$MatchReview {
  const factory MatchReview({
    required int id,
    required String matchId,
    required String reviewerId,
    required String reviewedId,
    required int rating,
    @Default(true) bool fairPlay,
    @Default(true) bool showedUp,
    String? comment,
    DateTime? createdAt,
    Profile? reviewer,
    Profile? reviewed,
  }) = _MatchReview;

  factory MatchReview.fromJson(Map<String, dynamic> json) => _$MatchReviewFromJson(json);
}
