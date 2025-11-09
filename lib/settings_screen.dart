import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'design_system.dart';
import 'widgets/professional_widgets.dart';

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
  final TextEditingController _watermarkTextController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  int _watermarkOption = 0; // 0: Text only, 1: Image only, 2: Both
  String? _watermarkImagePath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _companyNameController.text = prefs.getString('company_name') ?? '';
      _companyAddressController.text = prefs.getString('company_address') ?? '';
      _companyPhoneController.text = prefs.getString('company_phone') ?? '';
      _companyEmailController.text = prefs.getString('company_email') ?? '';
      _watermarkTextController.text = prefs.getString('watermarkText') ?? '';
      _watermarkImagePath = prefs.getString('watermarkImage');
      _watermarkOption = prefs.getInt('watermarkOption') ?? 0;
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
      await prefs.setString('watermarkText', _watermarkTextController.text);
      await prefs.setInt('watermarkOption', _watermarkOption);
      if (_watermarkImagePath != null) {
        await prefs.setString('watermarkImage', _watermarkImagePath!);
      }

      _showSnackBar('Settings saved successfully');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Failed to save settings', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickWatermarkImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _watermarkImagePath = image.path;
        });
        _showSnackBar('Watermark image selected');
      }
    } catch (e) {
      _showSnackBar('Failed to pick image', isError: true);
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
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Watermark Settings Section
                  _buildSectionHeader(
                    icon: Icons.branding_watermark_rounded,
                    title: 'Watermark Settings',
                    subtitle: 'Add watermark to your cash memos',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildSettingCard(
                    children: [
                      // Watermark Option Selector
                      Text(
                        'Watermark Type',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<int>(
                              title: const Text('Text Only'),
                              value: 0,
                              groupValue: _watermarkOption,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() => _watermarkOption = value!);
                              },
                            ),
                            const Divider(height: 1),
                            RadioListTile<int>(
                              title: const Text('Image Only'),
                              value: 1,
                              groupValue: _watermarkOption,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() => _watermarkOption = value!);
                              },
                            ),
                            const Divider(height: 1),
                            RadioListTile<int>(
                              title: const Text('Both Text and Image'),
                              value: 2,
                              groupValue: _watermarkOption,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() => _watermarkOption = value!);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Show text field if watermark includes text
                      if (_watermarkOption == 0 || _watermarkOption == 2) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildTextField(
                          controller: _watermarkTextController,
                          label: 'Watermark Text',
                          hint: 'Enter watermark text (e.g., CONFIDENTIAL)',
                          icon: Icons.text_fields_rounded,
                        ),
                      ],

                      // Show image picker if watermark includes image
                      if (_watermarkOption == 1 || _watermarkOption == 2) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watermark Image',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            InkWell(
                              onTap: _pickWatermarkImage,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.image_rounded,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        _watermarkImagePath != null
                                            ? 'Image selected'
                                            : 'Tap to select watermark image',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: _watermarkImagePath != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _watermarkTextController.dispose();
    super.dispose();
  }
}
