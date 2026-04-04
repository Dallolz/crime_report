import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/sport_config.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 2;

  // Sport selection: sport name -> selected
  final Set<String> _selectedSports = {};

  // Skill levels per sport
  final Map<String, String> _skillLevels = {};

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final allSports = SportConfig.allSports;

      // Build the list of selected sports with their IDs and skill levels.
      // We use the sport index + 1 as a simple mapping matching DB seed order.
      final sportsToSave = <Map<String, dynamic>>[];

      for (final sportName in _selectedSports) {
        final sportIndex =
            allSports.indexWhere((s) => s.name == sportName);
        sportsToSave.add({
          'sport_id': sportIndex + 1,
          'skill_level': _skillLevels[sportName] ?? 'beginner',
        });
      }

      await repo.saveSelectedSports(sportsToSave);

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildSportSelectionPage(),
                  _buildSkillLevelPage(),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: _currentPage == 0
                    ? FilledButton(
                        onPressed:
                            _selectedSports.isNotEmpty ? _nextPage : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Suivant (${_selectedSports.length} sport${_selectedSports.length > 1 ? 's' : ''})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : FilledButton(
                        onPressed: _isLoading ? null : _completeOnboarding,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Terminer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Sport Selection ──────────────────────────────────────────

  Widget _buildSportSelectionPage() {
    final sports = SportConfig.allSports;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Choisis tes sports',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selectionne au moins 1 sport pour commencer',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: sports.length,
              itemBuilder: (context, index) {
                final sport = sports[index];
                final isSelected = _selectedSports.contains(sport.name);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSports.remove(sport.name);
                        _skillLevels.remove(sport.name);
                      } else {
                        _selectedSports.add(sport.name);
                        _skillLevels[sport.name] = 'beginner';
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? sport.color.withOpacity(0.12)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? sport.color : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                sport.icon,
                                size: 36,
                                color:
                                    isSelected ? sport.color : Colors.grey[500],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                sport.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? sport.color
                                      : Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: sport.color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Skill Level Picker ───────────────────────────────────────

  Widget _buildSkillLevelPage() {
    final theme = Theme.of(context);

    const levels = ['beginner', 'intermediate', 'advanced', 'expert'];
    const levelLabels = {
      'beginner': 'Debutant',
      'intermediate': 'Intermediaire',
      'advanced': 'Avance',
      'expert': 'Expert',
    };
    const levelIcons = {
      'beginner': Icons.looks_one_outlined,
      'intermediate': Icons.looks_two_outlined,
      'advanced': Icons.looks_3_outlined,
      'expert': Icons.looks_4_outlined,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _previousPage,
                child: const Icon(Icons.arrow_back, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ton niveau par sport',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Evalue ton niveau pour un meilleur matchmaking',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _selectedSports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final sportName = _selectedSports.elementAt(index);
                final config = SportConfig.getSport(sportName);
                if (config == null) return const SizedBox.shrink();

                final currentLevel =
                    _skillLevels[sportName] ?? 'beginner';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sport header
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: config.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              config.icon,
                              color: config.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            config.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Skill level chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: levels.map((level) {
                          final isActive = currentLevel == level;
                          return ChoiceChip(
                            avatar: isActive
                                ? null
                                : Icon(
                                    levelIcons[level],
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                            label: Text(levelLabels[level]!),
                            selected: isActive,
                            selectedColor: config.color.withOpacity(0.2),
                            checkmarkColor: config.color,
                            labelStyle: TextStyle(
                              color: isActive
                                  ? config.color
                                  : Colors.grey[700],
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isActive
                                    ? config.color
                                    : Colors.grey[300]!,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(
                                    () => _skillLevels[sportName] = level);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
