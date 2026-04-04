import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge.freezed.dart';
part 'badge.g.dart';

@freezed
class Badge with _$Badge {
  const factory Badge({
    required int id,
    required String name,
    String? description,
    String? iconUrl,
    String? category,
    @Default({}) Map<String, dynamic> conditionJson,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
}

@freezed
class UserBadge with _$UserBadge {
  const factory UserBadge({
    required String userId,
    required int badgeId,
    DateTime? earnedAt,
    Badge? badge,
  }) = _UserBadge;

  factory UserBadge.fromJson(Map<String, dynamic> json) => _$UserBadgeFromJson(json);
}
