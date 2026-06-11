import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/providers.dart';
import '../domain/app_user.dart';

class ReferralSystemDialog extends StatefulWidget {
  final AppUser user;

  const ReferralSystemDialog({super.key, required this.user});

  @override
  State<ReferralSystemDialog> createState() => _ReferralSystemDialogState();
}

class _ReferralSystemDialogState extends State<ReferralSystemDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  Color _statusColor = Colors.grey;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitReferral(WidgetRef ref) async {
    final enteredCode = _codeController.text.trim().toUpperCase();
    if (enteredCode.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a referral code';
        _statusColor = Colors.red;
      });
      return;
    }

    if (enteredCode == widget.user.referralCode) {
      setState(() {
        _statusMessage = 'You cannot enter your own referral code';
        _statusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Verify if code exists in Firestore 'users' collection
      final querySnapshot = await firestore
          .collection('users')
          .where('referralCode', isEqualTo: enteredCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _statusMessage = 'Invalid referral code. Please check and try again.';
          _statusColor = Colors.red;
          _isLoading = false;
        });
        return;
      }

      // 2. Unlock Sakura theme & Referral badge rewards
      final currentAchievements = List<String>.from(widget.user.unlockedAchievements);
      if (!currentAchievements.contains('referral_supporter')) {
        currentAchievements.add('referral_supporter');
      }

      final updatedUser = widget.user.copyWith(
        referredBy: enteredCode,
        unlockedAchievements: currentAchievements,
        selectedTheme: 'sakura', // Auto-apply reward theme
      );

      // 3. Save to Firestore
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateUser(updatedUser);

      // Log growth event
      ref.read(analyticsServiceProvider).logAchievementUnlocked('referral_supporter');

      setState(() {
        _statusMessage = 'Success! Community Supporter badge and Sakura Theme unlocked!';
        _statusColor = Colors.green;
        _isLoading = false;
      });

      // Close dialog after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'An error occurred: $e';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Consumer(
        builder: (context, ref, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Referral Support',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter a friend\'s referral code to support each other. You will unlock the Community Supporter badge and a custom Sakura Blossom theme!',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 20),

                // Code Input Field
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Friend\'s Referral Code',
                    hintText: 'e.g. MOVEON-ABCDE',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group_add),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                if (_statusMessage != null) ...[
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitReferral(ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock Rewards'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
