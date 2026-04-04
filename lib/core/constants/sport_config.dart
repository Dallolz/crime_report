import 'package:flutter/material.dart';

class SportConfig {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final String emoji;

  const SportConfig({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.emoji,
  });

  static const Map<String, SportConfig> sports = {
    'football': SportConfig(
      name: 'football',
      displayName: 'Football',
      icon: Icons.sports_soccer,
      color: Color(0xFF4CAF50),
      emoji: '⚽',
    ),
    'basketball': SportConfig(
      name: 'basketball',
      displayName: 'Basketball',
      icon: Icons.sports_basketball,
      color: Color(0xFFFF9800),
      emoji: '🏀',
    ),
    'tennis': SportConfig(
      name: 'tennis',
      displayName: 'Tennis',
      icon: Icons.sports_tennis,
      color: Color(0xFFCDDC39),
      emoji: '🎾',
    ),
    'padel': SportConfig(
      name: 'padel',
      displayName: 'Padel',
      icon: Icons.sports_tennis,
      color: Color(0xFF2196F3),
      emoji: '🏓',
    ),
    'badminton': SportConfig(
      name: 'badminton',
      displayName: 'Badminton',
      icon: Icons.sports,
      color: Color(0xFF9C27B0),
      emoji: '🏸',
    ),
    'volleyball': SportConfig(
      name: 'volleyball',
      displayName: 'Volleyball',
      icon: Icons.sports_volleyball,
      color: Color(0xFFF44336),
      emoji: '🏐',
    ),
    'running': SportConfig(
      name: 'running',
      displayName: 'Running',
      icon: Icons.directions_run,
      color: Color(0xFF00BCD4),
      emoji: '🏃',
    ),
    'table_tennis': SportConfig(
      name: 'table_tennis',
      displayName: 'Ping-pong',
      icon: Icons.sports_cricket,
      color: Color(0xFFFF5722),
      emoji: '🏓',
    ),
    'boxing': SportConfig(
      name: 'boxing',
      displayName: 'Boxe / MMA',
      icon: Icons.sports_mma,
      color: Color(0xFF795548),
      emoji: '🥊',
    ),
    'cycling': SportConfig(
      name: 'cycling',
      displayName: 'Cyclisme',
      icon: Icons.directions_bike,
      color: Color(0xFF607D8B),
      emoji: '🚴',
    ),
  };

  static SportConfig? getSport(String name) => sports[name];

  static List<SportConfig> get allSports => sports.values.toList();
}
