import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

@freezed
class Activity with _$Activity {
  const factory Activity({
    required int id,
    required String actorId,
    required String actionType,
    String? targetType,
    String? targetId,
    @Default({}) Map<String, dynamic> metadata,
    DateTime? createdAt,
    Profile? actor,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
}
