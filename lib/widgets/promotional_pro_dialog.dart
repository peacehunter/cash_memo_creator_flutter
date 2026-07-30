import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system.dart';
import '../services/subscription_service.dart';
import 'premium_upgrade_sheet.dart';

/// SharedPreferences keys for startup promo frequency logic
const String kProPromoLaunchCountKey = 'pro_promo_launch_count';
const String kProPromoLastShownKey = 'pro_promo_last_shown_timestamp';

/// Helper function to check startup conditions and present the promotional Pro dialog
/// ONLY when appropriate ("not always").
///
/// Rules:
/// 1. Never show if user is already a Pro subscriber.
/// 2. Never show on the very 1st app launch (to allow privacy policy/onboarding first).
/// 3. Require a 24-hour cooldown between startup promos.
/// 4. Show on strategic launches (e.g. 2nd launch, and every 3 launches thereafter).
Future<void> showStartupProPromoIfNeeded(BuildContext context, {bool forceShow = false}) async {
  // Rule 1: Skip if already Pro
  if (SubscriptionService.instance.isProUser) {
    debugPrint('👑 [StartupProPromo] User is already Pro. Skipping promo.');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final int currentLaunches = prefs.getInt(kProPromoLaunchCountKey) ?? 0;
  final int launchCount = currentLaunches + 1;
  await prefs.setInt(kProPromoLaunchCountKey, launchCount);

  if (!forceShow) {
    // Rule 2: Skip on very 1st launch to avoid overwhelming new users
    if (launchCount < 2) {
      debugPrint('👑 [StartupProPromo] First launch (count=$launchCount). Skipping startup promo.');
      return;
    }

    // Rule 3: 24-hour Cooldown check
    final String? lastShownStr = prefs.getString(kProPromoLastShownKey);
    if (lastShownStr != null) {
      try {
        final lastShownDate = DateTime.parse(lastShownStr);
        final hoursSince = DateTime.now().difference(lastShownDate).inHours;
        if (hoursSince < 24) {
          debugPrint('👑 [StartupProPromo] Cooldown active ($hoursSince h < 24 h). Skipping.');
          return;
        }
      } catch (e) {
        debugPrint('👑 [StartupProPromo] Error parsing timestamp: $e');
      }
    }

    // Rule 4: Show on 2nd launch, and every 3rd launch thereafter (2, 5, 8, 11...)
    if ((launchCount - 2) % 3 != 0) {
      debugPrint('👑 [StartupProPromo] Launch count $launchCount not in frequency interval. Skipping.');
      return;
    }
  }

  if (!context.mounted) return;

  // Persist last shown timestamp
  await prefs.setString(kProPromoLastShownKey, DateTime.now().toIso8601String());
  debugPrint('👑 [StartupProPromo] Displaying promotional Pro subscription dialog (Launch #$launchCount).');

  if (!context.mounted) return;

  // Display the promotional dialog
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const PromotionalProDialog(),
  );
}

class PromotionalProDialog extends StatefulWidget {
  const PromotionalProDialog({super.key});

  /// Static helper to manually open the dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PromotionalProDialog(),
    );
  }

  @override
  State<PromotionalProDialog> createState() => _PromotionalProDialogState();
}

class _PromotionalProDialogState extends State<PromotionalProDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onUpgradePressed() {
    Navigator.of(context).pop(); // Close promo dialog
    // Open full upgrade sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PremiumUpgradeSheet.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final dialogWidth = (mediaQuery.size.width * 0.9).clamp(280.0, 420.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: 16,
          backgroundColor: Colors.white,
          child: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // ── Gradient Header ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6366F1), // Indigo
                        Color(0xFF8B5CF6), // Purple
                        Color(0xFFEC4899), // Pink
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Close button (top right)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      Column(
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          // Offer Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'LIMITED SPECIAL OFFER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Glowing Crown Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.amberAccent,
                              size: 52,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Title
                          const Text(
                            'Upgrade to Cash Memo Pro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            'Boost your business with unlimited memo creation & premium tools',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Body / Benefits List ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
                  child: Column(
                    children: [
                      const _BenefitRow(
                        icon: Icons.all_inclusive_rounded,
                        iconColor: Color(0xFF10B981),
                        title: 'Unlimited Memos & Invoices',
                        subtitle: 'No daily limits or restrictions',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _BenefitRow(
                        icon: Icons.palette_rounded,
                        iconColor: Color(0xFF8B5CF6),
                        title: 'All Premium PDF Templates',
                        subtitle: 'Access clean, modern & professional designs',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _BenefitRow(
                        icon: Icons.block_rounded,
                        iconColor: Color(0xFFEF4444),
                        title: '100% Ad-Free Experience',
                        subtitle: 'Zero ads, popup or banner interruptions',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _BenefitRow(
                        icon: Icons.business_center_rounded,
                        iconColor: Color(0xFF2563EB),
                        title: 'Logo & Customer Directory',
                        subtitle: 'Save customer list & add company branding',
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Discount Tag Pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer_rounded, color: Colors.amber, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Save up to 50% with Yearly Access!',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── CTA Buttons ──────────────────────────────────────
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppGradients.premium,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          onPressed: _onUpgradePressed,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Get Pro Access Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Maybe Later / Dismiss Button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Maybe Later',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF10B981),
          size: 18,
        ),
      ],
    );
  }
}
