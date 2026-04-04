import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

@freezed
class Venue with _$Venue {
  const factory Venue({
    required int id,
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    @Default([]) List<int> sportIds,
    @Default([]) List<String> photos,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    String? createdBy,
    @Default(false) bool isVerified,
    DateTime? createdAt,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
}
