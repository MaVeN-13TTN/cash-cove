import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  static SettingsService get to => Get.find();
  
  SharedPreferences? _prefs;
  
  bool get isInitialized => _prefs != null;

  // Theme settings
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  
  // Currency settings
  final RxString defaultCurrency = 'USD'.obs;
  
  // Notification settings
  final RxBool pushNotificationsEnabled = true.obs;
  final RxBool emailNotificationsEnabled = true.obs;
  final RxBool budgetAlertsEnabled = true.obs;
  final RxBool expenseRemindersEnabled = true.obs;
  
  // Privacy settings
  final RxBool biometricEnabled = false.obs;
  final RxBool analyticsEnabled = true.obs;
  
  // Display settings
  final RxString dateFormat = 'dd/MM/yyyy'.obs;
  final RxString timeFormat = '24h'.obs;
  final RxString numberFormat = 'comma'.obs;
  
  // Budget settings
  final RxBool autoRollover = false.obs;
  final RxInt budgetWarningThreshold = 80.obs; // percentage
  
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('SettingsService not properly initialized');
    }
    return _prefs!;
  }

  @override
  void onInit() {
    super.onInit();
    _initializePreferences();
  }
  
  void _initializePreferences() {
    try {
      if (!Get.isRegistered<SharedPreferences>()) {
        debugPrint('SharedPreferences not registered yet');
        return;
      }
      if (_prefs != null) {
        debugPrint('Preferences already initialized');
        return;
      }
      _prefs = Get.find<SharedPreferences>();
      loadSettings();
    } catch (e) {
      debugPrint('Error initializing preferences: $e');
    }
  }
  
  void loadSettings() {
    if (_prefs == null) return;
    
    // Theme settings
    themeMode.value = ThemeMode.values.byName(
      _prefs!.getString('themeMode') ?? ThemeMode.system.name
    );
    
    // Currency settings
    defaultCurrency.value = prefs.getString('defaultCurrency') ?? 'USD';
    
    // Notification settings
    pushNotificationsEnabled.value = prefs.getBool('pushNotifications') ?? true;
    emailNotificationsEnabled.value = prefs.getBool('emailNotifications') ?? true;
    budgetAlertsEnabled.value = prefs.getBool('budgetAlerts') ?? true;
    expenseRemindersEnabled.value = prefs.getBool('expenseReminders') ?? true;
    
    // Privacy settings
    biometricEnabled.value = prefs.getBool('biometric') ?? false;
    analyticsEnabled.value = prefs.getBool('analytics') ?? true;
    
    // Display settings
    dateFormat.value = prefs.getString('dateFormat') ?? 'dd/MM/yyyy';
    timeFormat.value = prefs.getString('timeFormat') ?? '24h';
    numberFormat.value = prefs.getString('numberFormat') ?? 'comma';
    
    // Budget settings
    autoRollover.value = prefs.getBool('autoRollover') ?? false;
    budgetWarningThreshold.value = prefs.getInt('budgetWarningThreshold') ?? 80;
  }
  
  Future<bool> updateThemeMode(ThemeMode mode) async {
    await prefs.setString('themeMode', mode.name);
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    return true;
  }
  
  Future<bool> updateDefaultCurrency(String currency) async {
    await prefs.setString('defaultCurrency', currency);
    defaultCurrency.value = currency;
    return true;
  }
  
  Future<bool> updatePushNotifications(bool enabled) async {
    await prefs.setBool('pushNotifications', enabled);
    pushNotificationsEnabled.value = enabled;
    return true;
  }
  
  Future<bool> updateEmailNotifications(bool enabled) async {
    await prefs.setBool('emailNotifications', enabled);
    emailNotificationsEnabled.value = enabled;
    return true;
  }
  
  Future<bool> updateBudgetAlerts(bool enabled) async {
    await prefs.setBool('budgetAlerts', enabled);
    budgetAlertsEnabled.value = enabled;
    return true;
  }
  
  Future<bool> updateExpenseReminders(bool enabled) async {
    await prefs.setBool('expenseReminders', enabled);
    expenseRemindersEnabled.value = enabled;
    return true;
  }
  
  Future<bool> updateBiometric(bool enabled) async {
    await prefs.setBool('biometric', enabled);
    biometricEnabled.value = enabled;
    return true;
  }
  
  Future<bool> updateAnalytics(bool enabled) async {
    await prefs.setBool('analytics', enabled);
    analyticsEnabled.value = enabled;
    return true;
  }
  
  Future<bool> updateDateFormat(String format) async {
    await prefs.setString('dateFormat', format);
    dateFormat.value = format;
    return true;
  }
  
  Future<bool> updateTimeFormat(String format) async {
    await prefs.setString('timeFormat', format);
    timeFormat.value = format;
    return true;
  }
  
  Future<bool> updateNumberFormat(String format) async {
    await prefs.setString('numberFormat', format);
    numberFormat.value = format;
    return true;
  }
  
  Future<bool> updateAutoRollover(bool enabled) async {
    await prefs.setBool('autoRollover', enabled);
    autoRollover.value = enabled;
    return true;
  }
  
  Future<bool> updateBudgetWarningThreshold(int threshold) async {
    await prefs.setInt('budgetWarningThreshold', threshold);
    budgetWarningThreshold.value = threshold;
    return true;
  }
  
  Future<bool> resetSettings() async {
    try {
      // Reset theme
      await prefs.setString('themeMode', ThemeMode.system.name);
      themeMode.value = ThemeMode.system;
      Get.changeThemeMode(ThemeMode.system);

      // Reset currency
      await prefs.setString('defaultCurrency', 'USD');
      defaultCurrency.value = 'USD';

      // Reset notification settings
      await prefs.setBool('pushNotifications', true);
      pushNotificationsEnabled.value = true;

      await prefs.setBool('emailNotifications', true);
      emailNotificationsEnabled.value = true;

      await prefs.setBool('budgetAlerts', true);
      budgetAlertsEnabled.value = true;

      await prefs.setBool('expenseReminders', true);
      expenseRemindersEnabled.value = true;

      // Reset privacy settings
      await prefs.setBool('biometric', false);
      biometricEnabled.value = false;

      await prefs.setBool('analytics', true);
      analyticsEnabled.value = true;

      // Reset display settings
      await prefs.setString('dateFormat', 'dd/MM/yyyy');
      dateFormat.value = 'dd/MM/yyyy';

      await prefs.setString('timeFormat', '24h');
      timeFormat.value = '24h';

      await prefs.setString('numberFormat', 'comma');
      numberFormat.value = 'comma';

      // Reset budget settings
      await prefs.setBool('autoRollover', false);
      autoRollover.value = false;

      await prefs.setInt('budgetWarningThreshold', 80);
      budgetWarningThreshold.value = 80;

      return true;
    } catch (e) {
      // Log the error or handle it appropriately
      Get.log('Error resetting settings: $e');
      return false;
    }
  }
  
  // Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'themeMode': themeMode.value.name,
      'defaultCurrency': defaultCurrency.value,
      'pushNotifications': pushNotificationsEnabled.value,
      'emailNotifications': emailNotificationsEnabled.value,
      'budgetAlerts': budgetAlertsEnabled.value,
      'expenseReminders': expenseRemindersEnabled.value,
      'biometric': biometricEnabled.value,
      'analytics': analyticsEnabled.value,
      'dateFormat': dateFormat.value,
      'timeFormat': timeFormat.value,
      'numberFormat': numberFormat.value,
      'autoRollover': autoRollover.value,
      'budgetWarningThreshold': budgetWarningThreshold.value,
    };
  }
  
  // Import settings
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      // Theme settings
      if (settings.containsKey('themeMode')) {
        final themeMode = ThemeMode.values.byName(settings['themeMode']);
        await prefs.setString('themeMode', themeMode.name);
        this.themeMode.value = themeMode;
        Get.changeThemeMode(themeMode);
      }

      // Currency settings
      if (settings.containsKey('defaultCurrency')) {
        await prefs.setString('defaultCurrency', settings['defaultCurrency']);
        defaultCurrency.value = settings['defaultCurrency'];
      }

      // Notification settings
      if (settings.containsKey('pushNotificationsEnabled')) {
        await prefs.setBool('pushNotifications', settings['pushNotificationsEnabled']);
        pushNotificationsEnabled.value = settings['pushNotificationsEnabled'];
      }

      if (settings.containsKey('emailNotificationsEnabled')) {
        await prefs.setBool('emailNotifications', settings['emailNotificationsEnabled']);
        emailNotificationsEnabled.value = settings['emailNotificationsEnabled'];
      }

      if (settings.containsKey('budgetAlertsEnabled')) {
        await prefs.setBool('budgetAlerts', settings['budgetAlertsEnabled']);
        budgetAlertsEnabled.value = settings['budgetAlertsEnabled'];
      }

      if (settings.containsKey('expenseRemindersEnabled')) {
        await prefs.setBool('expenseReminders', settings['expenseRemindersEnabled']);
        expenseRemindersEnabled.value = settings['expenseRemindersEnabled'];
      }

      // Privacy settings
      if (settings.containsKey('biometricEnabled')) {
        await prefs.setBool('biometric', settings['biometricEnabled']);
        biometricEnabled.value = settings['biometricEnabled'];
      }

      if (settings.containsKey('analyticsEnabled')) {
        await prefs.setBool('analytics', settings['analyticsEnabled']);
        analyticsEnabled.value = settings['analyticsEnabled'];
      }

      // Display settings
      if (settings.containsKey('dateFormat')) {
        await prefs.setString('dateFormat', settings['dateFormat']);
        dateFormat.value = settings['dateFormat'];
      }

      if (settings.containsKey('timeFormat')) {
        await prefs.setString('timeFormat', settings['timeFormat']);
        timeFormat.value = settings['timeFormat'];
      }

      if (settings.containsKey('numberFormat')) {
        await prefs.setString('numberFormat', settings['numberFormat']);
        numberFormat.value = settings['numberFormat'];
      }

      // Budget settings
      if (settings.containsKey('autoRollover')) {
        await prefs.setBool('autoRollover', settings['autoRollover']);
        autoRollover.value = settings['autoRollover'];
      }

      if (settings.containsKey('budgetWarningThreshold')) {
        await prefs.setInt('budgetWarningThreshold', settings['budgetWarningThreshold']);
        budgetWarningThreshold.value = settings['budgetWarningThreshold'];
      }

      return true;
    } catch (e, stackTrace) {
      // Use a proper logging mechanism instead of print
      Get.log('Error importing settings: $e');
      Get.log(stackTrace.toString());
      return false;
    }
  }
}
