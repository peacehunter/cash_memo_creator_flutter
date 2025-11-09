import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_ads/RewardedAdManager.dart';

class TemplateManager {
  // Templates 5, 6, 7, 8 are premium (require watching ad to unlock)
  static const List<int> premiumTemplates = [5, 6, 7, 8];

  // Check if a template is premium
  static bool isPremiumTemplate(int templateId) {
    return premiumTemplates.contains(templateId);
  }

  // Check if a template is unlocked
  static Future<bool> isTemplateUnlocked(int templateId) async {
    if (!isPremiumTemplate(templateId)) {
      return true; // Free templates are always unlocked
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('template_unlocked_$templateId') ?? false;
  }

  // Unlock a template by watching rewarded ad
  static Future<bool> unlockTemplate(
    int templateId,
    BuildContext context,
  ) async {
    final rewardedAdManager = RewardedAdManager();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Load the ad
    bool adLoaded = false;
    rewardedAdManager.loadRewardedAd(
      onAdLoaded: () {
        adLoaded = true;
        Navigator.pop(context); // Close loading dialog
      },
      onAdFailedToLoad: (error) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(context, 'Failed to load ad. Please try again.');
      },
    );

    // Wait for ad to load (max 5 seconds)
    await Future.delayed(const Duration(seconds: 5));

    if (!adLoaded) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        _showErrorDialog(context, 'Ad took too long to load. Please check your connection.');
      }
      return false;
    }

    // Show the ad
    bool rewardEarned = false;
    await rewardedAdManager.showRewardedAd(
      onUserEarnedReward: () async {
        rewardEarned = true;
        // Save unlock status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('template_unlocked_$templateId', true);
      },
      onAdFailed: () {
        if (context.mounted) {
          _showErrorDialog(context, 'Failed to show ad. Please try again.');
        }
      },
    );

    rewardedAdManager.dispose();
    return rewardEarned;
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
              child: const Row(
                children: [
                  Icon(Icons.play_circle, color: Colors.blue, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Watch a short video to unlock this template forever!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
