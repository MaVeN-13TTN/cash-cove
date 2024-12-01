import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences.dart';

class SettingsService extends GetxService {
  static SettingsService get to => Get.find();
  
  late final SharedPreferences _prefs;
  
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
  
  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    await loadSettings();
  }
  
  Future<void> loadSettings() async {
    // Theme settings
    themeMode.value = ThemeMode.values.byName(
      _prefs.getString('themeMode') ?? ThemeMode.system.name
    );
    
    // Currency settings
    defaultCurrency.value = _prefs.getString('defaultCurrency') ?? 'USD';
    
    // Notification settings
    pushNotificationsEnabled.value = _prefs.getBool('pushNotifications') ?? true;
    emailNotificationsEnabled.value = _prefs.getBool('emailNotifications') ?? true;
    budgetAlertsEnabled.value = _prefs.getBool('budgetAlerts') ?? true;
    expenseRemindersEnabled.value = _prefs.getBool('expenseReminders') ?? true;
    
    // Privacy settings
    biometricEnabled.value = _prefs.getBool('biometric') ?? false;
    analyticsEnabled.value = _prefs.getBool('analytics') ?? true;
    
    // Display settings
    dateFormat.value = _prefs.getString('dateFormat') ?? 'dd/MM/yyyy';
    timeFormat.value = _prefs.getString('timeFormat') ?? '24h';
    numberFormat.value = _prefs.getString('numberFormat') ?? 'comma';
    
    // Budget settings
    autoRollover.value = _prefs.getBool('autoRollover') ?? false;
    budgetWarningThreshold.value = _prefs.getInt('budgetWarningThreshold') ?? 80;
  }
  
  Future<void> updateThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs.setString('themeMode', mode.name);
    Get.changeThemeMode(mode);
  }
  
  Future<void> updateDefaultCurrency(String currency) async {
    defaultCurrency.value = currency;
    await _prefs.setString('defaultCurrency', currency);
  }
  
  Future<void> updatePushNotifications(bool enabled) async {
    pushNotificationsEnabled.value = enabled;
    await _prefs.setBool('pushNotifications', enabled);
  }
  
  Future<void> updateEmailNotifications(bool enabled) async {
    emailNotificationsEnabled.value = enabled;
    await _prefs.setBool('emailNotifications', enabled);
  }
  
  Future<void> updateBudgetAlerts(bool enabled) async {
    budgetAlertsEnabled.value = enabled;
    await _prefs.setBool('budgetAlerts', enabled);
  }
  
  Future<void> updateExpenseReminders(bool enabled) async {
    expenseRemindersEnabled.value = enabled;
    await _prefs.setBool('expenseReminders', enabled);
  }
  
  Future<void> updateBiometric(bool enabled) async {
    biometricEnabled.value = enabled;
    await _prefs.setBool('biometric', enabled);
  }
  
  Future<void> updateAnalytics(bool enabled) async {
    analyticsEnabled.value = enabled;
    await _prefs.setBool('analytics', enabled);
  }
  
  Future<void> updateDateFormat(String format) async {
    dateFormat.value = format;
    await _prefs.setString('dateFormat', format);
  }
  
  Future<void> updateTimeFormat(String format) async {
    timeFormat.value = format;
    await _prefs.setString('timeFormat', format);
  }
  
  Future<void> updateNumberFormat(String format) async {
    numberFormat.value = format;
    await _prefs.setString('numberFormat', format);
  }
  
  Future<void> updateAutoRollover(bool enabled) async {
    autoRollover.value = enabled;
    await _prefs.setBool('autoRollover', enabled);
  }
  
  Future<void> updateBudgetWarningThreshold(int threshold) async {
    budgetWarningThreshold.value = threshold;
    await _prefs.setInt('budgetWarningThreshold', threshold);
  }
  
  Future<void> resetSettings() async {
    await _prefs.clear();
    await loadSettings();
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
  Future<void> importSettings(Map<String, dynamic> settings) async {
    await _prefs.setString('themeMode', settings['themeMode']);
    await _prefs.setString('defaultCurrency', settings['defaultCurrency']);
    await _prefs.setBool('pushNotifications', settings['pushNotifications']);
    await _prefs.setBool('emailNotifications', settings['emailNotifications']);
    await _prefs.setBool('budgetAlerts', settings['budgetAlerts']);
    await _prefs.setBool('expenseReminders', settings['expenseReminders']);
    await _prefs.setBool('biometric', settings['biometric']);
    await _prefs.setBool('analytics', settings['analytics']);
    await _prefs.setString('dateFormat', settings['dateFormat']);
    await _prefs.setString('timeFormat', settings['timeFormat']);
    await _prefs.setString('numberFormat', settings['numberFormat']);
    await _prefs.setBool('autoRollover', settings['autoRollover']);
    await _prefs.setInt('budgetWarningThreshold', settings['budgetWarningThreshold']);
    
    await loadSettings();
  }
}
