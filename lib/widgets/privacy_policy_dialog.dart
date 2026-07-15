import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used to persist privacy policy acceptance.
const String kPrivacyPolicyAcceptedKey = 'privacy_policy_accepted';

/// Shows the [PrivacyPolicyDialog] if the user has not yet accepted.
/// Returns `true` if accepted, `false` if declined (app will exit).
Future<bool> showPrivacyPolicyIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final accepted = prefs.getBool(kPrivacyPolicyAcceptedKey) ?? false;
  if (accepted) return true;

  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PrivacyPolicyDialog(),
  );

  return result ?? false;
}

class PrivacyPolicyDialog extends StatefulWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onAccept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrivacyPolicyAcceptedKey, true);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _onDecline() {
    Navigator.of(context).pop(false);
    Future.delayed(const Duration(milliseconds: 300), () {
      SystemNavigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_outlined,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please review before continuing',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Policy body
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PolicySection(
                        icon: Icons.info_outline,
                        title: 'What We Collect',
                        body:
                            'Cash Memo Creator stores your memo data, company information, and app settings locally on your device. No account or login is required.',
                        color: colorScheme.secondary,
                      ),
                      _PolicySection(
                        icon: Icons.ads_click_outlined,
                        title: 'Advertisements',
                        body:
                            "We show ads powered by Google AdMob to keep the app free. AdMob may collect device identifiers and usage data to serve personalized ads in accordance with Google's Privacy Policy.",
                        color: const Color(0xFFf59e0b),
                      ),
                      _PolicySection(
                        icon: Icons.analytics_outlined,
                        title: 'Analytics & Crash Reports',
                        body:
                            'We use Firebase Analytics and Crashlytics to understand how the app is used and to fix crashes. This data is anonymous and not linked to your identity.',
                        color: const Color(0xFF6366f1),
                      ),
                      _PolicySection(
                        icon: Icons.lock_outline,
                        title: 'Data Storage',
                        body:
                            'All your memos and business data are stored only on your device. We do not upload or share your business or customer information.',
                        color: colorScheme.primary,
                      ),
                      _PolicySection(
                        icon: Icons.child_care_outlined,
                        title: "Children's Privacy",
                        body:
                            'This app is not directed at children under 13. We do not knowingly collect data from children.',
                        color: const Color(0xFFec4899),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By tapping Accept, you agree to our privacy practices as described above.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Divider
              Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.4)),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  children: [
                    // Decline
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onDecline,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.6)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Decline',
                          style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _onAccept,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Accept & Continue',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
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
    );
  }
}

class _PolicySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
