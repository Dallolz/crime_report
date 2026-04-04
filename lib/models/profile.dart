import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    double? latitude,
    double? longitude,
    String? city,
    @Default(0) int xpTotal,
    @Default(0) int streakDays,
    DateTime? lastActiveAt,
    DateTime? createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
