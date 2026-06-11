import 'package:flutter/material.dart';

class LegalScreens {
  LegalScreens._();

  static void showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy Policy 🛡️'),
          content: const SingleChildScrollView(
            child: Text(
              'Effective Date: June 12, 2026\n\n'
              'At Move On, we prioritize your emotional recovery and privacy. This Privacy Policy details how we handle user data.\n\n'
              '1. Data Collection & Storage:\n'
              '• All personal journal entries are stored locally on your device in secure encrypted Hive vaults. They are synced to private Google Cloud Firestore servers only to support data recovery across devices.\n'
              '• Mood check-in history, No Contact streak durations, triggers tracking clicks, and unsent letters vaults are saved securely in Google Cloud Firestore under your private authenticated user folder.\n\n'
              '2. Data Security:\n'
              '• Your data is protected by Firebase Security Rules that prevent any other users from reading or writing to your records. No third party has access to your emotional recovery logs.\n\n'
              '3. GDPR Compliance & Portability:\n'
              '• We support your right to data portability. You can export a copy of all your local journals, letters, and mood history in JSON format at any time from your settings.\n'
              '• We support your right to be forgotten. Triggering "Delete Account" permanently deletes your authentication record and wipes all Firestore user subcollections, leaving no trace on our servers.\n\n'
              '4. Third-Party Analytics:\n'
              '• We use Firebase Analytics and Crashlytics to monitor crash rates and app stability. No private journal text or letter content is ever logged or shared with analytics providers.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms of Service 📜'),
          content: const SingleChildScrollView(
            child: Text(
              'Effective Date: June 12, 2026\n\n'
              'Welcome to Move On. By signing up or using the application, you agree to these Terms of Service.\n\n'
              '1. Self-Help Tool Purpose:\n'
              '• Move On is an offline-first journal and emotional tracking utility designed to support self-care. It is NOT a substitute for professional mental health services, therapy, or medical counseling.\n'
              '• If you are experiencing severe distress or crisis, please seek immediate help from a certified mental health professional or counselor.\n\n'
              '2. User Obligations:\n'
              '• You are responsible for keeping your login credentials secure.\n'
              '• You agree not to exploit or reverse engineer any application services.\n\n'
              '3. Limitation of Liability:\n'
              '• Move On is provided "as-is" without warranty. We are not liable for any emotional distress, data loss, or system errors resulting from the use of the app.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
