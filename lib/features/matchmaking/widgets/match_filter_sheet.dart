import 'package:flutter/material.dart';

class MatchFilterSheet extends StatefulWidget {
  final String? initialSkill;
  final double initialDistance;

  const MatchFilterSheet({
    super.key,
    this.initialSkill,
    this.initialDistance = 50,
  });

  @override
  State<MatchFilterSheet> createState() => _MatchFilterSheetState();
}

class _MatchFilterSheetState extends State<MatchFilterSheet> {
  late String? _selectedSkill;
  late double _distance;

  static const _skillLevels = [
    (null, 'Tous les niveaux'),
    ('beginner', 'D\u00e9butant'),
    ('intermediate', 'Interm\u00e9diaire'),
    ('advanced', 'Avanc\u00e9'),
    ('expert', 'Expert'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSkill = widget.initialSkill;
    _distance = widget.initialDistance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Filtres',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Skill level
          Text(
            'Niveau',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _selectedSkill,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _skillLevels
                .map(
                  (s) => DropdownMenuItem<String?>(
                    value: s.$1,
                    child: Text(s.$2),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedSkill = value);
            },
          ),
          const SizedBox(height: 24),

          // Distance slider
          Text(
            'Distance : ${_distance.round()} km',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Slider(
            value: _distance,
            min: 5,
            max: 50,
            divisions: 9,
            label: '${_distance.round()} km',
            onChanged: (value) {
              setState(() => _distance = value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 km',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                '50 km',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'skill': _selectedSkill,
                  'distance': _distance,
                });
              },
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}
