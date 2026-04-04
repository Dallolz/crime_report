import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/matchmaking_provider.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _descriptionController = TextEditingController();

  int? _selectedSportId;
  String _matchType = 'quick';
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  String? _minSkill;
  String? _maxSkill;
  bool _isLoading = false;

  static const _skillLevels = [
    ('beginner', 'D\u00e9butant'),
    ('intermediate', 'Interm\u00e9diaire'),
    ('advanced', 'Avanc\u00e9'),
    ('expert', 'Expert'),
  ];

  @override
  void dispose() {
    _venueController.dispose();
    _addressController.dispose();
    _maxPlayersController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportsAsync = ref.watch(sportsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cr\u00e9er un match'),
      ),
      body: sportsAsync.when(
        data: (sports) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Sport dropdown
              DropdownButtonFormField<int>(
                value: _selectedSportId,
                decoration: const InputDecoration(
                  labelText: 'Sport',
                  prefixIcon: Icon(Icons.sports),
                ),
                items: sports
                    .map(
                      (s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          s['display_name'] ?? s['name'] ?? '',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedSportId = value),
                validator: (value) =>
                    value == null ? 'S\u00e9lectionne un sport' : null,
              ),
              const SizedBox(height: 20),

              // Match type toggle
              Text(
                'Type de match',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'quick',
                    label: Text('Rapide'),
                    icon: Icon(Icons.flash_on),
                  ),
                  ButtonSegment(
                    value: 'scheduled',
                    label: Text('Planifi\u00e9'),
                    icon: Icon(Icons.calendar_today),
                  ),
                ],
                selected: {_matchType},
                onSelectionChanged: (selection) {
                  setState(() => _matchType = selection.first);
                },
              ),
              const SizedBox(height: 20),

              // Date and time pickers for scheduled matches
              if (_matchType == 'scheduled') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _scheduledDate != null
                              ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                              : 'Date',
                        ),
                        onPressed: () => _pickDate(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _scheduledTime != null
                              ? '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                              : 'Heure',
                        ),
                        onPressed: () => _pickTime(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Venue name
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Nom du lieu',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'ex: Parc des Princes',
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: Icon(Icons.map),
                  hintText: 'ex: 24 Rue du Commandant Guilbaud',
                ),
              ),
              const SizedBox(height: 16),

              // Max players & duration
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxPlayersController,
                      decoration: const InputDecoration(
                        labelText: 'Joueurs max',
                        prefixIcon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Dur\u00e9e (min)',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Skill level range
              Text(
                'Niveau requis',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _minSkill,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Aucun'),
                        ),
                        ..._skillLevels.map(
                          (s) => DropdownMenuItem(
                            value: s.$1,
                            child: Text(s.$2),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _minSkill = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _maxSkill,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Aucun'),
                        ),
                        ..._skillLevels.map(
                          (s) => DropdownMenuItem(
                            value: s.$1,
                            child: Text(s.$2),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _maxSkill = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Infos suppl\u00e9mentaires...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createMatch,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cr\u00e9er le match'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('fr'),
    );
    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }

  Future<void> _createMatch() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(matchRepositoryProvider);

      DateTime? scheduledAt;
      if (_matchType == 'scheduled' &&
          _scheduledDate != null &&
          _scheduledTime != null) {
        scheduledAt = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      final result = await repo.createMatch(
        sportId: _selectedSportId!,
        creatorId: userId,
        matchType: _matchType,
        venueName: _venueController.text.isNotEmpty
            ? _venueController.text
            : null,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        scheduledAt: scheduledAt,
        durationMin: int.tryParse(_durationController.text),
        maxPlayers: int.tryParse(_maxPlayersController.text),
        minSkill: _minSkill,
        maxSkill: _maxSkill,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      if (mounted) {
        context.pushReplacement('/match/${result['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
