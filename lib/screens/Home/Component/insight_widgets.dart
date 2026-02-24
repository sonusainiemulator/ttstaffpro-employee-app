import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../utils/design_system.dart';
import '../../../main.dart';

class InsightWidgets extends StatelessWidget {
  const InsightWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Work Insights',
                style: boldTextStyle(
                  size: 18,
                  color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                ),
              ),
              Text(
                'View All',
                style: secondaryTextStyle(
                  size: 14,
                  color: AppDesignSystem.primaryColor,
                ),
              ).onTap(() {
                // Navigate to insights details
              }),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildProgressCard(
                title: 'Daily Progress',
                subtitle: '6.5 / 8 Hours',
                progress: 0.8,
                icon: Iconsax.timer_1,
                color: AppDesignSystem.primaryColor,
              ),
              16.width,
              _buildStatCard(
                title: 'Leave Balance',
                value: '12',
                unit: 'Days',
                icon: Iconsax.calendar_edit,
                color: AppDesignSystem.successColor,
              ),
              16.width,
              _buildStatCard(
                title: 'Pending Tasks',
                value: '05',
                unit: 'Tasks',
                icon: Iconsax.task,
                color: AppDesignSystem.warningColor,
              ),
              16.width,
              _buildEventCard(
                title: 'Next Holiday',
                date: '26 Jan',
                name: 'Republic Day',
                icon: Iconsax.gift,
                color: AppDesignSystem.infoColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String subtitle,
    required double progress,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowSmall,
        border: Border.all(
          color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(duration: 2000.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
          20.height,
          Text(
            title,
            style: secondaryTextStyle(
              size: 13,
              color: AppDesignSystem.neutral500,
            ),
          ),
          4.height,
          Text(
            subtitle,
            style: boldTextStyle(
              size: 16,
              color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowSmall,
        border: Border.all(
          color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .shimmer(duration: 3000.ms, color: color.withOpacity(0.2)),
          20.height,
          Text(
            title,
            style: secondaryTextStyle(
              size: 13,
              color: AppDesignSystem.neutral500,
            ),
          ),
          4.height,
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: boldTextStyle(
                    size: 24,
                    color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: secondaryTextStyle(
                    size: 12,
                    color: AppDesignSystem.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: white, size: 20),
              ),
              Text(
                date,
                style: boldTextStyle(color: white, size: 14),
              ),
            ],
          ),
          20.height,
          Text(
            title,
            style: secondaryTextStyle(
              size: 13,
              color: white.withOpacity(0.8),
            ),
          ),
          4.height,
          Text(
            name,
            style: boldTextStyle(
              size: 16,
              color: white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: 0.2, end: 0);
  }
}
