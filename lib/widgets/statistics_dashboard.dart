import 'package:flutter/material.dart';
import '../Memo.dart';
import '../design_system.dart';

/// Professional Statistics Dashboard
class StatisticsDashboard extends StatelessWidget {
  final List<Memo> memos;

  const StatisticsDashboard({Key? key, required this.memos}) : super(key: key);

  double get totalRevenue {
    return memos.fold(0.0, (sum, memo) => sum + memo.total);
  }

  int get totalCustomers {
    final uniqueCustomers = memos.map((m) => m.customerName.toLowerCase()).toSet();
    return uniqueCustomers.length;
  }

  double get averageOrderValue {
    if (memos.isEmpty) return 0.0;
    return totalRevenue / memos.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Total Memos',
                  value: memos.length.toString(),
                  color: AppColors.primary,
                  trend: '+${memos.length}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money_rounded,
                  title: 'Revenue',
                  value: '৳${totalRevenue.toStringAsFixed(0)}',
                  color: AppColors.secondary,
                  subtitle: 'Total',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_rounded,
                  title: 'Customers',
                  value: totalCustomers.toString(),
                  color: AppColors.accent,
                  subtitle: 'Unique',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Avg. Value',
                  value: '৳${averageOrderValue.toStringAsFixed(0)}',
                  color: AppColors.warning,
                  subtitle: 'Per memo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;
  final String? trend;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
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
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    trend!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.h2.copyWith(color: color, fontSize: 24),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    subtitle!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Professional Create Memo Button
class ProfessionalCreateButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final String subtitle;

  const ProfessionalCreateButton({
    Key? key,
    required this.onPressed,
    this.title = 'Create New Cash Memo',
    this.subtitle = 'Generate professional invoices instantly',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.colored(AppColors.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
