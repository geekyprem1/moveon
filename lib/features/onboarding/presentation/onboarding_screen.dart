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
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final years = int.tryParse(_yearsController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;
    final totalDays = (years * 365) + (months * 30);

    if (totalDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid relationship duration'),
        ),
      );
      return;
    }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tell Us Your Story',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Let’s set up your profile to personalize your healing path.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 24),

                // Question 1: Breakup Date
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. When did the breakup happen?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: isLoading ? null : () => _selectDate(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat.yMMMMd().format(_breakupDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.calendar_month_outlined),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Question 2: Relationship Duration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2. How long did the relationship last?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yearsController,
                                keyboardType: TextInputType.number,
                                enabled: !isLoading,
                                decoration: const InputDecoration(
                                  labelText: 'Years',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  if (int.tryParse(value) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _monthsController,
                                keyboardType: TextInputType.number,
                                enabled: !isLoading,
                                decoration: const InputDecoration(
                                  labelText: 'Months',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  final m = int.tryParse(value);
                                  if (m == null) return 'Invalid';
                                  if (m < 0 || m > 11) return '0 - 11';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Question 3: Breakup Type
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3. What describes your breakup?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _breakupTypes.map((type) {
                            final bool isSelected = _selectedBreakupType == type['name'];
                            return ChoiceChip(
                              label: Text('${type['icon']} ${type['name']}'),
                              selected: isSelected,
                              onSelected: isLoading
                                  ? null
                                  : (selected) {
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
                  ),
                ),
                const SizedBox(height: 16),

                // Question 4: Emotional Pain Score
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4. Emotional Pain Score (${_painScore.toInt()}/10)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '0 = No Pain, 10 = Intense Emotional Pain',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: _painScore,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _painScore.toInt().toString(),
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _painScore = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                      : const Text(
                          'Begin Journey',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
