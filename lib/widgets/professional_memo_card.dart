import 'package:flutter/material.dart';
import '../Memo.dart';
import '../design_system.dart';
import 'package:intl/intl.dart';

/// Professional Memo Card with modern design
class ProfessionalMemoCard extends StatelessWidget {
  final Memo memo;
  final int index;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final Function(int) onPrint;

  const ProfessionalMemoCard({
    Key? key,
    required this.memo,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  }) : super(key: key);

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onEdit(index),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info Row
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: AppShadows.colored(AppColors.primary),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        // Customer Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memo.customerName,
                                style: AppTypography.h3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 14,
                                    color: AppColors.neutral500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      memo.customerPhoneNumber,
                                      style: AppTypography.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Quick Actions Menu
                        _QuickActionsButton(
                          onEdit: () => onEdit(index),
                          onDelete: () => onDelete(index),
                          onPrint: () => onPrint(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                color: AppColors.border,
              ),

              // Details Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    // Amount and Date Row
                    Row(
                      children: [
                        // Total Amount
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.attach_money_rounded,
                            label: 'Total Amount',
                            value: '৳${memo.total.toStringAsFixed(2)}',
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        // Date
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: memo.date != null && memo.date!.isNotEmpty
                                ? _formatDate(memo.date!)
                                : 'N/A',
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Products Info
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.shopping_bag_rounded,
                            label: 'Items',
                            value: '${memo.products.length}',
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        // Discount/VAT if applicable
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.local_offer_rounded,
                            label: 'Discount',
                            value: memo.discount > 0
                                ? '${memo.discount.toStringAsFixed(1)}%'
                                : 'None',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Footer with Action Buttons
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.lg),
                    bottomRight: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onPressed: () => onEdit(index),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Print Button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.print_rounded,
                        label: 'Print',
                        onPressed: () => onPrint(index),
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Delete Button
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: '',
                      onPressed: () => onDelete(index),
                      color: AppColors.error,
                      iconOnly: true,
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

// Info Tile Widget
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool iconOnly;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly ? AppSpacing.md : AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: iconOnly ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: 18, color: color),
              if (!iconOnly) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.button.copyWith(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Quick Actions Menu Button
class _QuickActionsButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const _QuickActionsButton({
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: AppColors.primary),
              title: Text('Edit Memo', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(Icons.print_rounded, color: AppColors.secondary),
              title: Text('Print Memo', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onPrint();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text('Delete Memo', style: AppTypography.bodyLarge.copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMenu(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: AppColors.neutral600,
          ),
        ),
      ),
    );
  }
}
