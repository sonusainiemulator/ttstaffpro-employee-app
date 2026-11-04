import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/screens/Account/account_screen.dart';
import 'package:open_core_hr/screens/Home/home_screen.dart';
import 'package:open_core_hr/screens/Permission/permissions_screen.dart';
import 'package:open_core_hr/screens/Leave/leave_dashboard_screen.dart';
import 'package:open_core_hr/screens/Expense/ExpenseScreen.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';

class NavigationScreen extends StatefulWidget {
  static String tag = '/NavigationScreen';
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    setDarkStatusBar();
    await appStore.refreshAttendanceStatus();
    // if (globalAttendanceStore.isKillDevice) {
    //   toast(language.lblYourDeviceIsRestrictedToUseThisAppPleaseContactAdmin);
    //   if (!mounted) return;
    //   sharedHelper.logout(context);
    // }

    // Check permissions in navigation screen (main screen)
    await checkAllPermissions();

    setupFirebase();
    // Device validation removed - only needed for Field Sales app
  }

  void setupFirebase() {
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      log("message received");
      log(event.notification!.body);
      if (!mounted) return;
      snackBar(
        context,
        title: event.notification!.title!,
        content: Text(event.notification!.body!),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log('Message clicked!');
    });
  }

  Future<void> checkAllPermissions() async {
    // Check if we've already shown the permission screen
    var hasShownPermissionScreen = getBoolAsync(
      'hasShownPermissionScreen',
      defaultValue: false,
    );

    if (!hasShownPermissionScreen) {
      // First time - check if notification permission is granted
      var isNotificationGranted =
          await Permission.notification.status.isGranted;

      if (!isNotificationGranted) {
        // Permission not granted - show permission screen
        if (!mounted) return;
        PermissionScreen().launch(context, isNewTask: true);
      } else {
        // Permission already granted, just mark as shown
        await setValue('hasShownPermissionScreen', true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = [
      const HomeScreen(),
      if (moduleService.isLeaveModuleEnabled()) const LeaveDashboardScreen(),
      if (moduleService.isExpenseModuleEnabled()) const ExpenseScreen(),
      const AccountScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }

        if (_currentIndex == 0) {
          if (await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(language.lblExitApp),
                    content: Text(language.lblAreYouSureYouWantToExit),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(language.lblNo),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(language.lblYes),
                      ),
                    ],
                  );
                },
              ) ??
              false) {
            SystemNavigator.pop();
          }
        } else {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: null,
        body: tab[_currentIndex],
        bottomNavigationBar: Observer(
          builder: (_) {
            final theme = Theme.of(context);
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _buildNavItems(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    List<Widget> items = [];
    int currentIndex = 0;

    // Home - Always included
    items.add(
      _modernNavItem(
        icon: Iconsax.home_1,
        activeIcon: Iconsax.home5,
        label: language.lblHome,
        index: currentIndex++,
      ),
    );

    // Leave - Included feature (not paid addon)
    if (moduleService.isLeaveModuleEnabled()) {
      items.add(
        _modernNavItem(
          icon: Iconsax.calendar,
          activeIcon: Iconsax.calendar5,
          label: language.lblLeaves,
          index: currentIndex++,
        ),
      );
    }

    // Expense - Included feature (not paid addon)
    if (moduleService.isExpenseModuleEnabled()) {
      items.add(
        _modernNavItem(
          icon: Iconsax.money_send,
          activeIcon: Iconsax.money_send5,
          label: language.lblExpense,
          index: currentIndex++,
        ),
      );
    }

    // Account - Always included
    items.add(
      _modernNavItem(
        icon: Iconsax.user,
        activeIcon: Iconsax.user_octagon,
        label: language.lblAccount,
        index: currentIndex++,
      ),
    );

    return items;
  }

  Widget _modernNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
                size: 21,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
