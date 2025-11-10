import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_ads/RewardedAdManager.dart';

class TemplateManager {
  // Templates 5, 6, 7, 8 are premium (require watching ad to unlock)
  static const List<int> premiumTemplates = [5, 6, 7, 8];

  // Number of uses per ad watch
  static const int usesPerUnlock = 3;

  // Check if a template is premium
  static bool isPremiumTemplate(int templateId) {
    return premiumTemplates.contains(templateId);
  }

  // Check if a template is unlocked (with usage-based expiry)
  static Future<bool> isTemplateUnlocked(int templateId) async {
    if (!isPremiumTemplate(templateId)) {
      return true; // Free templates are always unlocked
    }

    final prefs = await SharedPreferences.getInstance();
    final remainingUses = prefs.getInt('template_remaining_uses_$templateId') ?? 0;

    return remainingUses > 0;
  }

  // Get remaining uses for unlocked template
  static Future<int> getRemainingUses(int templateId) async {
    if (!isPremiumTemplate(templateId)) {
      return -1; // Free templates have unlimited uses
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('template_remaining_uses_$templateId') ?? 0;
  }

  // Consume one use of a template
  static Future<void> consumeTemplateUse(int templateId) async {
    if (!isPremiumTemplate(templateId)) {
      return; // Free templates don't need consumption tracking
    }

    final prefs = await SharedPreferences.getInstance();
    final remainingUses = prefs.getInt('template_remaining_uses_$templateId') ?? 0;

    if (remainingUses > 0) {
      final newCount = remainingUses - 1;
      await prefs.setInt('template_remaining_uses_$templateId', newCount);
      print('🔓 [TemplateManager] Template $templateId consumed. Remaining: $newCount uses');

      // Show feedback to user
      if (newCount == 0) {
        print('🔓 [TemplateManager] Template $templateId uses exhausted. Watch ad to unlock again.');
      }
    }
  }

  // Format remaining uses as string
  static String formatRemainingUses(int uses) {
    return uses == 1 ? '1 use left' : '$uses uses left';
  }

  // Unlock a template by watching rewarded ad
  static Future<bool> unlockTemplate(
    int templateId,
    BuildContext context,
  ) async {
    print('🔓 [TemplateManager] Starting unlock process for template $templateId');

    final rewardedAdManager = RewardedAdManager();

    // Check failed attempts count for this template
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt('template_failed_attempts_$templateId') ?? 0;
    print('🔓 [TemplateManager] Failed attempts: $failedAttempts');

    // If user has failed 3 times, offer alternative
    if (failedAttempts >= 3) {
      print('🔓 [TemplateManager] 3 failures detected, showing fallback dialog');
      final shouldUnlockAnyway = await _showFallbackDialog(context, templateId);
      if (shouldUnlockAnyway) {
        // Give 3 uses via fallback
        await prefs.setInt('template_remaining_uses_$templateId', usesPerUnlock);
        await prefs.remove('template_failed_attempts_$templateId');
        print('🔓 [TemplateManager] Template unlocked via fallback ($usesPerUnlock uses)');
        return true;
      }
      print('🔓 [TemplateManager] User declined fallback unlock');
      return false;
    }

    // Show loading dialog
    print('🔓 [TemplateManager] Showing loading dialog');
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading ad...'),
            ],
          ),
        ),
      );
    }

    // Load the ad
    bool adLoaded = false;
    bool loadFailed = false;
    String? loadError;

    print('🔓 [TemplateManager] Starting ad load...');
    rewardedAdManager.loadRewardedAd(
      onAdLoaded: () {
        print('🔓 [TemplateManager] ✅ Ad loaded successfully!');
        adLoaded = true;
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
        }
      },
      onAdFailedToLoad: (error) {
        print('🔓 [TemplateManager] ❌ Ad failed to load: $error');
        loadFailed = true;
        loadError = error.toString();
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
        }
      },
    );

    // Wait for ad to load (max 8 seconds)
    int waitTime = 0;
    while (!adLoaded && !loadFailed && waitTime < 8000) {
      await Future.delayed(const Duration(milliseconds: 500));
      waitTime += 500;
      if (waitTime % 2000 == 0) {
        print('🔓 [TemplateManager] Waiting for ad... ${waitTime}ms elapsed');
      }
    }

    // Close loading dialog if still open
    if (context.mounted && !adLoaded && !loadFailed) {
      print('🔓 [TemplateManager] ⏱️ Timeout waiting for ad');
      Navigator.pop(context);
    }

    if (!adLoaded || loadFailed) {
      print('🔓 [TemplateManager] Ad load failed. Error: $loadError');
      // Increment failed attempts
      await prefs.setInt('template_failed_attempts_$templateId', failedAttempts + 1);

      if (context.mounted) {
        final remaining = 3 - (failedAttempts + 1);
        if (remaining > 0) {
          _showErrorDialog(
            context,
            'Failed to load ad. Please check your internet connection.\n\n'
            'Attempts remaining: $remaining\n\n'
            'Debug: ${loadError ?? "Timeout"}',
          );
        } else {
          _showErrorDialog(
            context,
            'Ad loading failed multiple times. You can now unlock this template for free!',
          );
        }
      }
      rewardedAdManager.dispose();
      print('🔓 [TemplateManager] Returning false (ad failed to load)');
      return false;
    }

    // Show the ad and wait for completion
    print('🔓 [TemplateManager] Showing rewarded ad...');
    final rewardEarned = await rewardedAdManager.showRewardedAd();
    print('🔓 [TemplateManager] Ad completed. Reward earned: $rewardEarned');

    if (rewardEarned) {
      // Give 3 uses
      await prefs.setInt('template_remaining_uses_$templateId', usesPerUnlock);
      await prefs.remove('template_failed_attempts_$templateId');
      print('🔓 [TemplateManager] ✅ Template $templateId unlocked successfully! ($usesPerUnlock uses)');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Template unlocked! 3 uses available'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('🔓 [TemplateManager] ❌ Reward not earned');
      // Increment failed attempts
      await prefs.setInt('template_failed_attempts_$templateId', failedAttempts + 1);

      if (context.mounted) {
        _showErrorDialog(
          context,
          'You did not complete watching the ad. Please try again.',
        );
      }
    }

    rewardedAdManager.dispose();
    print('🔓 [TemplateManager] Unlock process complete. Returning: $rewardEarned');
    return rewardEarned;
  }

  // Show fallback dialog when ads fail 3 times
  static Future<bool> _showFallbackDialog(
    BuildContext context,
    int templateId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('Free Unlock!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We noticed ads aren\'t loading for you.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'As a thank you for your patience, you can now unlock this premium template for free!',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.lock_open),
            label: const Text('Unlock for Free'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Show unlock dialog for premium templates
  static Future<bool> showUnlockDialog(
    BuildContext context,
    int templateId,
    String templateName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Premium Template',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$templateName is a premium template.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Watch a short video to unlock',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number, size: 14, color: Colors.green.shade800),
                              const SizedBox(width: 4),
                              Text(
                                '3 uses',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.videocam),
            label: const Text('Watch & Unlock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Helper to show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Get template name
  static String getTemplateName(int templateId) {
    switch (templateId) {
      case 1:
        return 'Professional Classic';
      case 2:
        return 'Modern Elegance';
      case 3:
        return 'Minimalist Clean';
      case 4:
        return 'Modern Accent';
      case 5:
        return 'Bold Gradient';
      case 6:
        return 'Executive Professional';
      case 7:
        return 'Creative Modern';
      case 8:
        return 'Elegant Minimalist';
      default:
        return 'Template $templateId';
    }
  }
}
