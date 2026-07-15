import 'package:flutter/material.dart';
import '../design_system.dart';
import '../services/subscription_service.dart';

class PremiumUpgradeSheet extends StatefulWidget {
  const PremiumUpgradeSheet({Key? key}) : super(key: key);

  /// Helper static method to display the bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PremiumUpgradeSheet(),
    );
  }

  @override
  State<PremiumUpgradeSheet> createState() => _PremiumUpgradeSheetState();
}

class _PremiumUpgradeSheetState extends State<PremiumUpgradeSheet> {
  int _selectedPlanIndex = 2; // Default to Yearly (Best Value)
  bool _isProcessing = false;

  final List<Map<String, String>> _plans = [
    {
      'title': 'Weekly',
      'price': '\$2.49',
      'period': '/wk',
      'saving': '',
    },
    {
      'title': 'Monthly',
      'price': '\$7.99',
      'period': '/mo',
      'saving': 'SAVE 25%',
    },
    {
      'title': 'Yearly',
      'price': '\$47.99',
      'period': '/yr',
      'saving': 'SAVE 50%',
    }
  ];

  final List<String> _benefits = [
    'Unlock All Premium Templates (5, 6, 7, 8)',
    '100% Ad-Free Experience (No Banners/Interstitials)',
    'Unlimited Invoice/Cash Memo Generation',
    'Upload Custom Business Logo',
    'Manage Customer & Client Directory'
  ];

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    SubscriptionService.instance.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (mounted && SubscriptionService.instance.isProUser) {
      if (_isProcessing) {
        setState(() {
          _isProcessing = false;
        });
      }
      Navigator.pop(context); // Close bottom sheet
      _showSuccessDialog();
    }
  }

  Future<void> _handleSubscribe() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await SubscriptionService.instance.purchaseSubscription(_selectedPlanIndex);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await SubscriptionService.instance.restorePurchases();
      // Wait to see if purchase updates trigger
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted && !SubscriptionService.instance.isProUser) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No active purchases found to restore.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Golden Crown
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 3),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Welcome to Pro!',
                style: AppTypography.display2.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'All premium templates, features, and ad-free experience have been unlocked for your account.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppGradients.premium,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Let's Go!",
                    style: AppTypography.buttonLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.viewPadding.top;
    
    return Container(
      margin: EdgeInsets.only(top: topPadding + 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pull bar
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Crown Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.15),
                        const Color(0xFFEC4899).withOpacity(0.15),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => AppGradients.premium.createShader(bounds),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Get Cash Memo Pro',
                  style: AppTypography.display2.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Unlock all templates and premium business tools',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Benefits list
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: _benefits.map((benefit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD1FAE5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.secondary,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                benefit,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Plans Selection
                Row(
                  children: List.generate(_plans.length, (index) {
                    final plan = _plans[index];
                    final isSelected = _selectedPlanIndex == index;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlanIndex = index;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 0 : AppSpacing.sm,
                            right: index == _plans.length - 1 ? 0 : AppSpacing.sm,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xl,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.neutral50,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8B5CF6) : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    plan['title']!,
                                    style: AppTypography.label.copyWith(
                                      color: isSelected ? const Color(0xFF8B5CF6) : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            plan['price']!,
                                            style: AppTypography.display2.copyWith(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 1),
                                      Text(
                                        plan['period']!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (plan['saving']!.isNotEmpty)
                                Positioned(
                                  top: -30,
                                  right: 0,
                                  left: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: AppGradients.premium,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Text(
                                        plan['saving']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Checkout button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppGradients.premium,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    onPressed: _handleSubscribe,
                    child: Text(
                      'Subscribe Now',
                      style: AppTypography.buttonLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Restore Purchase / Legal Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _handleRestore,
                      child: Text(
                        'Restore Purchase',
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('|', style: TextStyle(color: AppColors.neutral300)),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Terms & Privacy',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Processing transaction securely...',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
