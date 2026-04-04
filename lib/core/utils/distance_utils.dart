class DistanceUtils {
  /// Format distance in human-readable form
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
    return '${distanceKm.round()} km';
  }

  /// Calculate matchmaking distance score (0.0 to 1.0)
  /// 1.0 if < 5km, linear decrease to 0.0 at 50km
  static double distanceScore(double distanceKm) {
    if (distanceKm <= 5) return 1.0;
    if (distanceKm >= 50) return 0.0;
    return 1.0 - ((distanceKm - 5) / 45);
  }
}
