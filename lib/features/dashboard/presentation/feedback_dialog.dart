import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/domain/app_user.dart';

class FeedbackDialog extends StatefulWidget {
  final AppUser user;

  const FeedbackDialog({super.key, required this.user});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _helpingController = TextEditingController();
  final _improveController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _helpingController.dispose();
    _improveController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final helpingText = _helpingController.text.trim();
    final improveText = _improveController.text.trim();

    if (helpingText.isEmpty && improveText.isEmpty) {
      setState(() {
        _statusMessage = 'Please fill out at least one question';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('feedback').doc();
      await docRef.set({
        'id': docRef.id,
        'uid': widget.user.uid,
        'email': widget.user.email,
        'helping': helpingText,
        'improve': improveText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback helps us build a better app.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to submit feedback: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Feedback 📝',
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
              'Your thoughts help us improve. Let us know how your healing process is going.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 20),

            // Question 1
            Text(
              'What is helping you most in Move On?',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _helpingController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Unsent letters, breathing exercises, no contact streak...',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Question 2
            Text(
              'What should we improve?',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _improveController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. More achievements, customizable themes, specific widgets...',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            if (_statusMessage != null) ...[
              Text(
                _statusMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _isLoading ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
