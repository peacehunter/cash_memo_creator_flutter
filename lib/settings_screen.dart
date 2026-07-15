import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system.dart';
import 'widgets/professional_widgets.dart';
import 'product_catalog_screen.dart';
import 'customer_directory_screen.dart';
import 'services/subscription_service.dart';
import 'widgets/premium_upgrade_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _specialNoteController = TextEditingController();
  final TextEditingController _customCurrencyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _specialNoteEnabled = false;
  String _selectedCurrency = '৳';
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.addListener(_onSubscriptionChanged);
    _loadSettings();
  }

  void _onSubscriptionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _companyNameController.text = prefs.getString('company_name') ?? '';
      _companyAddressController.text = prefs.getString('company_address') ?? '';
      _companyPhoneController.text = prefs.getString('company_phone') ?? '';
      _companyEmailController.text = prefs.getString('company_email') ?? '';
      _specialNoteEnabled = prefs.getBool('special_note_enabled') ?? false;
      _specialNoteController.text = prefs.getString('special_note') ?? '';
      _logoPath = prefs.getString('companyLogo') ?? '';
      
      String curr = prefs.getString('currency_symbol') ?? '৳';
      if (['৳', '\$', '€', '£', '₹', '¥', 'Rp', 'AED'].contains(curr)) {
        _selectedCurrency = curr;
      } else {
        _selectedCurrency = 'Custom';
        _customCurrencyController.text = curr;
      }
    } catch (e) {
      _showSnackBar('Failed to load settings', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('company_name', _companyNameController.text);
      await prefs.setString('company_address', _companyAddressController.text);
      await prefs.setString('company_phone', _companyPhoneController.text);
      await prefs.setString('company_email', _companyEmailController.text);
      await prefs.setBool('special_note_enabled', _specialNoteEnabled);
      await prefs.setString('special_note', _specialNoteController.text);
      await prefs.setString('companyLogo', _logoPath ?? '');

      String currencyToSave = _selectedCurrency == 'Custom' 
          ? _customCurrencyController.text 
          : _selectedCurrency;
      if (currencyToSave.isEmpty) currencyToSave = '৳';
      await prefs.setString('currency_symbol', currencyToSave);

      _showSnackBar('Settings saved successfully');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Failed to save settings', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickLogo() async {
    final isPro = SubscriptionService.instance.isProUser;
    if (!isPro) {
      PremiumUpgradeSheet.show(context);
      return;
    }
    if (kIsWeb) {
      _showSnackBar('Logo upload is not supported on Web.', isError: true);
      return;
    }
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _logoPath = image.path;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to select image', isError: true);
    }
  }


  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: ProfessionalLoading())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pro Subscription Card Section
                  Builder(
                    builder: (context) {
                      final isPro = SubscriptionService.instance.isProUser;
                      if (isPro) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Pro Subscription',
                              subtitle: 'Manage your premium membership status',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                gradient: AppGradients.premium,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEC4899).withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                                          SizedBox(width: 12),
                                          Text(
                                            'Pro Plan Active',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: const Text(
                                          '✨ ACTIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Thank you for subscribing! You have unlocked all professional templates, removed all advertisements, and enabled unlimited invoice creation.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF8B5CF6),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                        ),
                                        onPressed: () async {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Cancel Subscription?'),
                                              content: const Text(
                                                'This is a sandbox environment. Cancelling will revert your account to the Free Plan.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Keep Pro'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    await SubscriptionService.instance.cancelSubscription();
                                                  },
                                                  child: const Text('Cancel Plan', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.cancel_rounded, size: 18),
                                        label: const Text('Cancel Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Pro Subscription',
                              subtitle: 'Upgrade your account to access pro features',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppShadows.sm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Upgrade to Cash Memo Pro',
                                              style: AppTypography.labelMedium.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              'Ad-free & unlock all templates',
                                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Get access to all 8 invoices, remove all popup & banner ads, and enable advanced client and catalog controls.',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.premium,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                      ),
                                      onPressed: () {
                                        PremiumUpgradeSheet.show(context);
                                      },
                                      child: const Text(
                                        'Upgrade Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        );
                      }
                    },
                  ),
                  // Company Information Section
                  _buildSectionHeader(
                    icon: Icons.business_rounded,
                    title: 'Company Information',
                    subtitle: 'This information will appear on your cash memos',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildSettingCard(
                    children: [
                      _buildTextField(
                        controller: _companyNameController,
                        label: 'Company Name',
                        hint: 'Enter your company name',
                        icon: Icons.business_center_rounded,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _companyAddressController,
                        label: 'Company Address',
                        hint: 'Enter your company address',
                        icon: Icons.location_on_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _companyPhoneController,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _companyEmailController,
                        label: 'Email Address',
                        hint: 'Enter email address',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 20,
                            color: SubscriptionService.instance.isProUser
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Company Logo',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (!SubscriptionService.instance.isProUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _logoPath == null || _logoPath!.isEmpty
                            ? InkWell(
                                onTap: _pickLogo,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_rounded,
                                      size: 32,
                                      color: SubscriptionService.instance.isProUser
                                          ? AppColors.primary
                                          : AppColors.textTertiary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      SubscriptionService.instance.isProUser
                                          ? 'Tap to upload logo'
                                          : 'Upgrade to upload logo 🔒',
                                      style: TextStyle(
                                        color: SubscriptionService.instance.isProUser
                                            ? AppColors.textSecondary
                                            : AppColors.textTertiary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        child: Image.file(
                                          File(_logoPath!),
                                          height: 90,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.broken_image_rounded,
                                              color: AppColors.error,
                                              size: 32,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _logoPath = '';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.textSecondary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Special Note Section
                  _buildSectionHeader(
                    icon: Icons.note_add_rounded,
                    title: 'Special Note',
                    subtitle: 'Add a note that appears on all cash memos',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildSettingCard(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Special Note',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Show special note on all templates',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _specialNoteEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() => _specialNoteEnabled = value);
                            },
                          ),
                        ],
                      ),
                      if (_specialNoteEnabled) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildTextField(
                          controller: _specialNoteController,
                          label: 'Special Note Text',
                          hint: 'E.g., Thank you for your business. Payment due within 30 days.',
                          icon: Icons.edit_note_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // App Preferences Section
                  _buildSectionHeader(
                    icon: Icons.tune_rounded,
                    title: 'App Preferences',
                    subtitle: 'Configure currency formatting',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildSettingCard(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Global Currency',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select default currency symbol',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedCurrency,
                            icon: const Icon(Icons.arrow_drop_down),
                            underline: const SizedBox(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCurrency = newValue;
                                });
                              }
                            },
                            items: <String>['৳', '\$', '€', '£', '₹', '¥', 'Rp', 'AED', 'Custom']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      if (_selectedCurrency == 'Custom') ...[
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _customCurrencyController,
                          decoration: InputDecoration(
                            labelText: 'Custom Currency Symbol',
                            hintText: 'e.g., USD',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Business Assets Section
                  _buildSectionHeader(
                    icon: Icons.folder_shared_rounded,
                    title: 'Business Assets',
                    subtitle: 'Manage saved customers and product catalog',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildSettingCard(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
                        ),
                        title: const Text('Product Catalog', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Set up standard products, prices, and discounts'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProductCatalogScreen()),
                          );
                        },
                      ),
                      const Divider(height: AppSpacing.xl),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            color: SubscriptionService.instance.isProUser
                                ? AppColors.secondary
                                : AppColors.textTertiary,
                          ),
                        ),
                        title: Row(
                          children: [
                            const Text('Customer Directory', style: TextStyle(fontWeight: FontWeight.w600)),
                            if (!SubscriptionService.instance.isProUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: const Text('Manage repeat customer profiles and addresses'),
                        trailing: Icon(
                          SubscriptionService.instance.isProUser
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.lock_rounded,
                          size: 16,
                          color: SubscriptionService.instance.isProUser
                              ? AppColors.textTertiary
                              : Colors.amber,
                        ),
                        onTap: () {
                          if (SubscriptionService.instance.isProUser) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CustomerDirectoryScreen()),
                            );
                          } else {
                            PremiumUpgradeSheet.show(context);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // App Information Section
                  _buildSectionHeader(
                    icon: Icons.info_rounded,
                    title: 'About',
                    subtitle: 'Application information',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildSettingCard(
                    children: [
                      _buildInfoRow('Version', '1.0.0'),
                      const Divider(height: AppSpacing.xl),
                      _buildInfoRow('Developer', 'Cash Memo Creator Team'),
                      const Divider(height: AppSpacing.xl),
                      _buildInfoRow('Last Updated', 'December 2024'),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ProfessionalButton(
                      text: _isSaving ? 'Saving...' : 'Save Settings',
                      icon: Icons.save_rounded,
                      onPressed: _isSaving ? null : _saveSettings,
                      isLoading: _isSaving,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: ProfessionalOutlineButton(
                      text: 'Cancel',
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    SubscriptionService.instance.removeListener(_onSubscriptionChanged);
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _specialNoteController.dispose();
    super.dispose();
  }
}
