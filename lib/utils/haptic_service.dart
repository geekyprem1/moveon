import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService(ref);
});

class HapticService {
  final Ref _ref;

  HapticService(this._ref);

  bool get _isEnabled {
    final user = _ref.read(appUserProvider).value;
    return user?.hapticsEnabled ?? true;
  }

  /// Trigger a standard selection click (e.g. for tabs, options, choices)
  void selection() {
    if (_isEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Trigger a light impact (e.g. for sub-actions, opening detail views, minor tools)
  void light() {
    if (_isEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Trigger a medium impact (e.g. for confirmations, task completion, saving drafts)
  void medium() {
    if (_isEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Trigger a success impact (e.g. heavy impact for milestones)
  void success() {
    if (_isEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Trigger an extra heavy dual-beat success haptic (e.g. for achievements)
  Future<void> heavySuccess() async {
    if (_isEnabled) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.mediumImpact();
    }
  }

  /// Trigger a warning vibration (e.g. for deletions, streak resets, errors)
  void warning() {
    if (_isEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
