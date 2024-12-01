import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          SettingsSection(
            title: 'Account',
            children: [
              SettingsTile(
                leading: const Icon(Icons.person_outline),
                title: 'Name',
                subtitle: controller.userName,
                onTap: () {}, // TODO: Implement name edit
              ),
              SettingsTile(
                leading: const Icon(Icons.email_outlined),
                title: 'Email',
                subtitle: controller.userEmail,
                onTap: () {}, // TODO: Implement email edit
              ),
              SettingsTile(
                leading: const Icon(Icons.logout),
                title: 'Sign Out',
                onTap: controller.signOut,
              ),
              SettingsTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: 'Delete Account',
                titleColor: Colors.red,
                onTap: controller.deleteAccount,
              ),
            ],
          ),

          // Appearance Section
          SettingsSection(
            title: 'Appearance',
            children: [
              Obx(() => SettingsTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: 'Theme',
                subtitle: controller.themeMode.value.name.capitalizeFirst,
                onTap: () => _showThemeDialog(context),
              )),
              Obx(() => SettingsTile(
                leading: const Icon(Icons.attach_money),
                title: 'Default Currency',
                subtitle: controller.defaultCurrency.value,
                onTap: () => _showCurrencyDialog(context),
              )),
            ],
          ),

          // Notifications Section
          SettingsSection(
            title: 'Notifications',
            children: [
              Obx(() => SettingsTile.switchTile(
                leading: const Icon(Icons.notifications_outlined),
                title: 'Push Notifications',
                value: controller.pushNotificationsEnabled.value,
                onChanged: controller.updatePushNotifications,
              )),
              Obx(() => SettingsTile.switchTile(
                leading: const Icon(Icons.email_outlined),
                title: 'Email Notifications',
                value: controller.emailNotificationsEnabled.value,
                onChanged: controller.updateEmailNotifications,
              )),
              Obx(() => SettingsTile.switchTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: 'Budget Alerts',
                value: controller.budgetAlertsEnabled.value,
                onChanged: controller.updateBudgetAlerts,
              )),
              Obx(() => SettingsTile.switchTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: 'Expense Reminders',
                value: controller.expenseRemindersEnabled.value,
                onChanged: controller.updateExpenseReminders,
              )),
            ],
          ),

          // Privacy Section
          SettingsSection(
            title: 'Privacy',
            children: [
              Obx(() => SettingsTile.switchTile(
                leading: const Icon(Icons.fingerprint),
                title: 'Biometric Authentication',
                value: controller.biometricEnabled.value,
                onChanged: controller.updateBiometric,
              )),
              Obx(() => SettingsTile.switchTile(
                leading: const Icon(Icons.analytics_outlined),
                title: 'Analytics',
                subtitle: 'Help us improve by sharing usage data',
                value: controller.analyticsEnabled.value,
                onChanged: controller.updateAnalytics,
              )),
            ],
          ),

          // Display Section
          SettingsSection(
            title: 'Display',
            children: [
              Obx(() => SettingsTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: 'Date Format',
                subtitle: controller.dateFormat.value,
                onTap: () => _showDateFormatDialog(context),
              )),
              Obx(() => SettingsTile(
                leading: const Icon(Icons.access_time_outlined),
                title: 'Time Format',
                subtitle: controller.timeFormat.value,
                onTap: () => _showTimeFormatDialog(context),
              )),
              Obx(() => SettingsTile(
                leading: const Icon(Icons.numbers_outlined),
                title: 'Number Format',
                subtitle: controller.numberFormat.value,
                onTap: () => _showNumberFormatDialog(context),
              )),
            ],
          ),

          // Budget Section
          SettingsSection(
            title: 'Budget',
            children: [
              Obx(() => SettingsTile.switchTile(
                leading: const Icon(Icons.autorenew),
                title: 'Auto Rollover',
                subtitle: 'Automatically roll over unused budget',
                value: controller.autoRollover.value,
                onChanged: controller.updateAutoRollover,
              )),
              Obx(() => SettingsTile(
                leading: const Icon(Icons.warning_amber_outlined),
                title: 'Warning Threshold',
                subtitle: '${controller.budgetWarningThreshold.value}% of budget',
                onTap: () => _showThresholdDialog(context),
              )),
            ],
          ),

          // Data Management Section
          SettingsSection(
            title: 'Data Management',
            children: [
              SettingsTile(
                leading: const Icon(Icons.restore),
                title: 'Reset Settings',
                onTap: controller.resetSettings,
              ),
              SettingsTile(
                leading: const Icon(Icons.upload_outlined),
                title: 'Export Settings',
                onTap: controller.exportSettings,
              ),
              SettingsTile(
                leading: const Icon(Icons.download_outlined),
                title: 'Import Settings',
                onTap: () {}, // TODO: Implement settings import UI
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () {
                controller.updateThemeMode(ThemeMode.system);
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Light'),
              leading: const Icon(Icons.brightness_high),
              onTap: () {
                controller.updateThemeMode(ThemeMode.light);
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: const Icon(Icons.brightness_4),
              onTap: () {
                controller.updateThemeMode(ThemeMode.dark);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.availableCurrencies.length,
            itemBuilder: (context, index) {
              final currency = controller.availableCurrencies[index];
              return ListTile(
                title: Text(currency),
                onTap: () {
                  controller.updateDefaultCurrency(currency);
                  Get.back();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDateFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.availableDateFormats
              .map((format) => ListTile(
                    title: Text(format),
                    onTap: () {
                      controller.updateDateFormat(format);
                      Get.back();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showTimeFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.availableTimeFormats
              .map((format) => ListTile(
                    title: Text(format),
                    onTap: () {
                      controller.updateTimeFormat(format);
                      Get.back();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showNumberFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Number Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.availableNumberFormats
              .map((format) => ListTile(
                    title: Text(format.capitalizeFirst!),
                    onTap: () {
                      controller.updateNumberFormat(format);
                      Get.back();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showThresholdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [50, 60, 70, 80, 90]
              .map((threshold) => ListTile(
                    title: Text('$threshold%'),
                    onTap: () {
                      controller.updateBudgetWarningThreshold(threshold);
                      Get.back();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}