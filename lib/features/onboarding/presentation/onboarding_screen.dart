import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _formKeyStep2 = GlobalKey<FormState>();

  int _currentPage = 0;
  DateTime _breakupDate = DateTime.now().subtract(const Duration(days: 1));
  final _yearsController = TextEditingController(text: '0');
  final _monthsController = TextEditingController(text: '0');
  double _painScore = 5.0;
  String _selectedBreakupType = 'Toxic Relationship';

  final List<Map<String, String>> _breakupTypes = [
    {'name': 'Cheating', 'icon': '💔'},
    {'name': 'Toxic Relationship', 'icon': '⚠️'},
    {'name': 'One-Sided Love', 'icon': '🥀'},
    {'name': 'Situationship', 'icon': '❓'},
    {'name': 'Mutual Breakup', 'icon': '🤝'},
    {'name': 'Divorce', 'icon': '💍'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _yearsController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _breakupDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _breakupDate) {
      setState(() {
        _breakupDate = picked;
      });
    }
  }

  void _nextPage() {
    if (_currentPage == 1) {
      // Validate Step 2 inputs
      if (!_formKeyStep2.currentState!.validate()) return;
      final years = int.tryParse(_yearsController.text) ?? 0;
      final months = int.tryParse(_monthsController.text) ?? 0;
      final totalDays = (years * 365) + (months * 30);
      if (totalDays <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid relationship duration')),
        );
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    final years = int.tryParse(_yearsController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;
    final totalDays = (years * 365) + (months * 30);

    final controller = ref.read(onboardingControllerProvider.notifier);
    final success = await controller.submitOnboarding(
      breakupDate: _breakupDate,
      relationshipDurationDays: totalDays,
      initialPainScore: _painScore.toInt(),
      breakupType: _selectedBreakupType,
    );

    if (!mounted) return;

    if (!success) {
      final errorState = ref.read(onboardingControllerProvider);
      String errorMessage = 'Failed to save onboarding info. Please try again.';
      if (errorState is AsyncError) {
        errorMessage = errorState.error.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final isLoading = onboardingState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tell Us Your Story',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear progress indicator at the top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 4.0,
                  minHeight: 8.0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentPage + 1} of 4',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${((_currentPage + 1) / 4.0 * 100).toInt()}% Complete',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Page view containing steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Force navigation via buttons
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme),
                  _buildStep4(theme),
                ],
              ),
            ),

            // Bottom Navigation Actions Row
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _previousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Next / Submit Button
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : _currentPage < 3
                            ? _nextPage
                            : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentPage < 3 ? 'Next' : 'Begin Journey',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Date of Breakup
  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '💔',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'When did the breakup happen?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We use this date to initialize your No Contact streak. Postponing communication is key to breaking emotional dependence.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primaryContainer.withAlpha(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECTED DATE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMd().format(_breakupDate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.calendar_month, color: theme.colorScheme.primary, size: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Relationship Duration
  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '⏳',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              'How long did your relationship last?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Knowing your relationship length helps us contextualize your attachment intensity.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final y = int.tryParse(value);
                      if (y == null || y < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _monthsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Months',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timelapse),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final m = int.tryParse(value);
                      if (m == null || m < 0 || m > 11) return '0 - 11';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Breakup Type
  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '🥀',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'What describes your breakup?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Every breakup type requires a slightly different emotional frame of mind to heal.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: _breakupTypes.map((type) {
              final bool isSelected = _selectedBreakupType == type['name'];
              return ChoiceChip(
                label: Text('${type['icon']} ${type['name']}'),
                selected: isSelected,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                selectedColor: theme.colorScheme.primaryContainer,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedBreakupType = type['name']!;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // STEP 4: Pain Score
  Widget _buildStep4(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '🧠',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'Rate your current emotional pain',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Be completely honest with yourself. This sets a baseline for your recovery logs.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 36),
          Card(
            color: theme.colorScheme.primaryContainer.withAlpha(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pain Level',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_painScore.toInt()} / 10',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _painScore <= 3
                        ? 'Mild discomfort. You are holding up ok.'
                        : _painScore <= 6
                            ? 'Moderate pain. Cravings and nostalgia are frequent.'
                            : 'Intense pain. You feel overwhelmed. We are here to help.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _painScore,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _painScore.toInt().toString(),
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _painScore = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
