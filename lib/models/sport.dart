import 'package:freezed_annotation/freezed_annotation.dart';

part 'sport.freezed.dart';
part 'sport.g.dart';

@freezed
class Sport with _$Sport {
  const factory Sport({
    required int id,
    required String name,
    required String displayName,
    String? iconUrl,
    @Default(1) int teamSizeMin,
    @Default(1) int teamSizeMax,
    @Default('individual') String matchFormat,
    @Default(60) int defaultDurationMin,
    @Default({}) Map<String, dynamic> rulesJson,
  }) = _Sport;

  factory Sport.fromJson(Map<String, dynamic> json) => _$SportFromJson(json);
}
