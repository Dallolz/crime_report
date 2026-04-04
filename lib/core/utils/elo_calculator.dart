import '../constants/app_constants.dart';

class EloCalculator {
  /// Calculate new ELO ratings after a match
  /// [result] is 1.0 for win, 0.5 for draw, 0.0 for loss
  static int calculateNewRating({
    required int playerRating,
    required int opponentRating,
    required double result,
    required int matchesPlayed,
  }) {
    final k = matchesPlayed >= AppConstants.expertThresholdMatches
        ? AppConstants.eloKFactorExpert
        : AppConstants.eloKFactorBeginner;

    final expectedScore = _expectedScore(playerRating, opponentRating);
    final newRating = playerRating + (k * (result - expectedScore)).round();

    return newRating.clamp(100, 3000);
  }

  /// Calculate expected score between two players
  static double _expectedScore(int playerRating, int opponentRating) {
    return 1.0 / (1.0 + _pow10((opponentRating - playerRating) / 400.0));
  }

  static double _pow10(double exponent) {
    double result = 1.0;
    double base = 10.0;
    int n = exponent.abs().toInt();
    double frac = exponent.abs() - n;

    for (int i = 0; i < n; i++) {
      result *= base;
    }

    // Approximate fractional part
    if (frac > 0) {
      result *= 1 + frac * 2.302585; // ln(10) approximation for small fractions
    }

    return exponent < 0 ? 1.0 / result : result;
  }

  /// For team matches: calculate average ELO of a team
  static int teamAverageElo(List<int> ratings) {
    if (ratings.isEmpty) return AppConstants.defaultEloRating;
    return (ratings.reduce((a, b) => a + b) / ratings.length).round();
  }

  /// Get skill level label based on ELO
  static String skillLevelFromElo(int elo) {
    if (elo < 800) return 'beginner';
    if (elo < 1200) return 'intermediate';
    if (elo < 1600) return 'advanced';
    return 'expert';
  }

  /// Get display string for ELO
  static String eloDisplay(int elo) {
    final level = skillLevelFromElo(elo);
    return '$elo ($level)';
  }
}
