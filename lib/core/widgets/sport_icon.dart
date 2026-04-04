import 'package:flutter/material.dart';
import '../constants/sport_config.dart';

class SportIcon extends StatelessWidget {
  final String sportName;
  final double size;
  final bool showLabel;

  const SportIcon({
    super.key,
    required this.sportName,
    this.size = 48,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = SportConfig.getSport(sportName);
    if (config == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: config.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(size / 4),
          ),
          child: Icon(
            config.icon,
            color: config.color,
            size: size * 0.55,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            config.displayName,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
