import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../utils/design_system.dart';
import '../../../main.dart';

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

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
                'Recent Activity',
                style: boldTextStyle(
                  size: 18,
                  color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                ),
              ),
              Icon(
                Iconsax.more,
                color: AppDesignSystem.neutral500,
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: 3,
          separatorBuilder: (context, index) => 12.height,
          itemBuilder: (context, index) {
            final activities = [
              {
                'title': 'Check-in Successful',
                'time': '09:00 AM Today',
                'icon': Iconsax.login,
                'color': AppDesignSystem.successColor,
              },
              {
                'title': 'Leave Approved',
                'time': 'Yesterday',
                'icon': Iconsax.calendar_tick,
                'color': AppDesignSystem.primaryColor,
              },
              {
                'title': 'Payroll Generated',
                'time': '2 days ago',
                'icon': Iconsax.wallet_check,
                'color': AppDesignSystem.infoColor,
              },
            ];
            final activity = activities[index];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppDesignSystem.shadowSmall,
                border: Border.all(
                  color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['color'] as Color,
                      size: 20,
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          style: boldTextStyle(
                            size: 14,
                            color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                          ),
                        ),
                        4.height,
                        Text(
                          activity['time'] as String,
                          style: secondaryTextStyle(
                            size: 12,
                            color: AppDesignSystem.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: AppDesignSystem.neutral400,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 100).ms, duration: 600.ms).slideX(begin: 0.1, end: 0);
          },
        ),
      ],
    );
  }
}
