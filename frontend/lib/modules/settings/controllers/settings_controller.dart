import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/settings/settings_service.dart';
import '../../../core/services/auth/auth_service.dart';
import 'package:local_auth/local_auth.dart';

class SettingsController extends GetxController {
  final _settingsService = Get.find<SettingsService>();
  final _authService = Get.find<AuthService>();
  final _localAuth = LocalAuthentication();

  // Theme settings
  Rx<ThemeMode> get themeMode => _settingsService.themeMode;
  
  // Currency settings
  RxString get defaultCurrency => _settingsService.defaultCurrency;
  
  // Notification settings
  RxBool get pushNotificationsEnabled => _settingsService.pushNotificationsEnabled;
  RxBool get emailNotificationsEnabled => _settingsService.emailNotificationsEnabled;
  RxBool get budgetAlertsEnabled => _settingsService.budgetAlertsEnabled;
  RxBool get expenseRemindersEnabled => _settingsService.expenseRemindersEnabled;
  
  // Privacy settings
  RxBool get biometricEnabled => _settingsService.biometricEnabled;
  RxBool get analyticsEnabled => _settingsService.analyticsEnabled;
  
  // Display settings
  RxString get dateFormat => _settingsService.dateFormat;
  RxString get timeFormat => _settingsService.timeFormat;
  RxString get numberFormat => _settingsService.numberFormat;
  
  // Budget settings
  RxBool get autoRollover => _settingsService.autoRollover;
  RxInt get budgetWarningThreshold => _settingsService.budgetWarningThreshold;

  // User info
  String get userEmail => _authService.email;
  String get userName => _authService.displayName;

  // Available options
  final List<String> availableCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'KES'];
  final List<String> availableDateFormats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
  final List<String> availableTimeFormats = ['12h', '24h'];
  final List<String> availableNumberFormats = ['comma', 'space', 'indian'];

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _settingsService.updateThemeMode(mode);
  }

  Future<void> updateDefaultCurrency(String currency) async {
    await _settingsService.updateDefaultCurrency(currency);
  }

  Future<void> updatePushNotifications(bool enabled) async {
    await _settingsService.updatePushNotifications(enabled);
  }

  Future<void> updateEmailNotifications(bool enabled) async {
    await _settingsService.updateEmailNotifications(enabled);
  }

  Future<void> updateBudgetAlerts(bool enabled) async {
    await _settingsService.updateBudgetAlerts(enabled);
  }

  Future<void> updateExpenseReminders(bool enabled) async {
    await _settingsService.updateExpenseReminders(enabled);
  }

  Future<void> updateBiometric(bool enabled) async {
    if (enabled) {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        Get.snackbar(
          'Error',
          'Biometric authentication is not available on this device',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Enable biometric authentication',
        );

        if (didAuthenticate) {
          await _settingsService.updateBiometric(true);
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to enable biometric authentication',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      await _settingsService.updateBiometric(false);
    }
  }

  Future<void> updateAnalytics(bool enabled) async {
    await _settingsService.updateAnalytics(enabled);
  }

  Future<void> updateDateFormat(String format) async {
    await _settingsService.updateDateFormat(format);
  }

  Future<void> updateTimeFormat(String format) async {
    await _settingsService.updateTimeFormat(format);
  }

  Future<void> updateNumberFormat(String format) async {
    await _settingsService.updateNumberFormat(format);
  }

  Future<void> updateAutoRollover(bool enabled) async {
    await _settingsService.updateAutoRollover(enabled);
  }

  Future<void> updateBudgetWarningThreshold(int threshold) async {
    await _settingsService.updateBudgetWarningThreshold(threshold);
  }

  Future<void> resetSettings() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.resetSettings();
      Get.snackbar(
        'Success',
        'Settings have been reset to default',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> exportSettings() async {
    final exportedSettings = _settingsService.exportSettings();
    
    // TODO: Implement settings export functionality
    // This could save to a file, share via platform share functionality, etc.
    Get.snackbar(
      'Export Settings',
      'Exported settings: ${exportedSettings.toString()}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      await _settingsService.importSettings(settings);
      Get.snackbar(
        'Success',
        'Settings imported successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to import settings',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signOut() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      Get.offAllNamed('/auth/login');
    }
  }

  Future<void> deleteAccount() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.deleteAccount();
        Get.offAllNamed('/auth/login');
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete account. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}