import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kOnboardingShownKey = 'onboarding_shown';

/// Shows the [OnboardingOverlay] as a full-screen route if not yet seen.
Future<void> showOnboardingIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final shown = prefs.getBool(kOnboardingShownKey) ?? false;
  if (shown) return;
  if (!context.mounted) return;

  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => const OnboardingOverlay(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _OnboardingStep {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final List<_FeatureChip> chips;

  const _OnboardingStep({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    this.chips = const [],
  });
}

class _FeatureChip {
  final IconData icon;
  final String label;
  const _FeatureChip(this.icon, this.label);
}

const List<_OnboardingStep> _steps = [
  _OnboardingStep(
    icon: Icons.add_circle_outline_rounded,
    iconBg: Color(0xFFe6f7f1),
    iconColor: Color(0xFF059669),
    title: 'Create a Memo or Invoice',
    description:
        'Tap the ➕ button on the home screen to instantly create a new cash memo or invoice. Add products, prices, discounts, and taxes in seconds.',
    chips: [
      _FeatureChip(Icons.receipt_long, 'Cash Memos'),
      _FeatureChip(Icons.description_outlined, 'Invoices'),
      _FeatureChip(Icons.percent, 'VAT & Discount'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.list_alt_rounded,
    iconBg: Color(0xFFe8eaf6),
    iconColor: Color(0xFF3949ab),
    title: 'Manage Your Memos',
    description:
        'All saved memos are listed on the home screen. Tap any memo to edit it, swipe for quick actions, or use the menu to share, print, or delete.',
    chips: [
      _FeatureChip(Icons.edit_outlined, 'Edit'),
      _FeatureChip(Icons.share_outlined, 'Share'),
      _FeatureChip(Icons.search, 'Search'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.picture_as_pdf_rounded,
    iconBg: Color(0xFFfef3e2),
    iconColor: Color(0xFFd97706),
    title: 'Export & Print as PDF',
    description:
        'Preview any memo as a professional PDF. Share it via WhatsApp, email, or print directly from your phone. Multiple templates available.',
    chips: [
      _FeatureChip(Icons.preview, 'PDF Preview'),
      _FeatureChip(Icons.print_outlined, 'Print'),
      _FeatureChip(Icons.style_outlined, 'Templates'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.settings_outlined,
    iconBg: Color(0xFFfce4ec),
    iconColor: Color(0xFFe91e63),
    title: 'Customize Your Settings',
    description:
        'Go to Settings to add your company name, logo, address, and choose your preferred currency, language, and memo layout.',
    chips: [
      _FeatureChip(Icons.business_outlined, 'Company Info'),
      _FeatureChip(Icons.language, 'Language'),
      _FeatureChip(Icons.attach_money, 'Currency'),
    ],
  ),
];

// ─── Main overlay widget ──────────────────────────────────────────────────────

class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _buttonAnim;

  @override
  void initState() {
    super.initState();
    _buttonAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnim.dispose();
    super.dispose();
  }

  Future<void> _markDoneAndClose() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingShownKey, true);
    if (mounted) Navigator.of(context).pop();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _markDoneAndClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Pages ─────────────────────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) =>
                  _StepPage(step: _steps[index], index: index),
            ),

            // ── Skip button (top-right) ───────────────────────────────────
            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _markDoneAndClose,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? _steps[i].iconColor
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Next / Done button
                    GestureDetector(
                      onTapDown: (_) => _buttonAnim.reverse(),
                      onTapUp: (_) {
                        _buttonAnim.forward();
                        _nextPage();
                      },
                      onTapCancel: () => _buttonAnim.forward(),
                      child: ScaleTransition(
                        scale: _buttonAnim,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _steps[_currentPage].iconColor,
                                _steps[_currentPage].iconColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _steps[_currentPage]
                                    .iconColor
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _currentPage < _steps.length - 1
                                  ? 'Next  →'
                                  : 'Get Started  🚀',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual step page ─────────────────────────────────────────────────────

class _StepPage extends StatefulWidget {
  final _OnboardingStep step;
  final int index;

  const _StepPage({required this.step, required this.index});

  @override
  State<_StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<_StepPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _iconScaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _iconScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 60, 28, 160),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon circle
              ScaleTransition(
                scale: _iconScaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: step.iconBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: step.iconColor.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(step.icon, size: 54, color: step.iconColor),
                ),
              ),
              const SizedBox(height: 36),

              // Step number badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: step.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: step.iconColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  'Step ${widget.index + 1} of ${_steps.length}',
                  style: TextStyle(
                    color: step.iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // Description
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 15,
                  height: 1.55,
                ),
              ),

              // Feature chips
              if (step.chips.isNotEmpty) ...[
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: step.chips
                      .map((chip) => _FeatureChipWidget(
                            chip: chip,
                            color: step.iconColor,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChipWidget extends StatelessWidget {
  final _FeatureChip chip;
  final Color color;

  const _FeatureChipWidget({required this.chip, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            chip.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
