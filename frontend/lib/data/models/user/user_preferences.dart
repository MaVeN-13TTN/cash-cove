import 'package:json_annotation/json_annotation.dart';

part 'user_preferences.g.dart';

@JsonSerializable()
class UserPreferences {
  final String defaultCurrency;
  final bool darkMode;
  final bool notificationsEnabled;
  final List<String> favoriteCategories;
  final String language;
  final bool biometricEnabled;
  final Map<String, dynamic> budgetAlerts;

  UserPreferences({
    this.defaultCurrency = 'USD',
    this.darkMode = false,
    this.notificationsEnabled = true,
    List<String>? favoriteCategories,
    this.language = 'en',
    this.biometricEnabled = false,
    Map<String, dynamic>? budgetAlerts,
  })  : favoriteCategories = favoriteCategories ?? [],
        budgetAlerts = budgetAlerts ?? {
          'enabled': true,
          'thresholds': [50, 80, 90, 100],
        };

  // Copy with method for immutability
  UserPreferences copyWith({
    String? defaultCurrency,
    bool? darkMode,
    bool? notificationsEnabled,
    List<String>? favoriteCategories,
    String? language,
    bool? biometricEnabled,
    Map<String, dynamic>? budgetAlerts,
  }) {
    return UserPreferences(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      language: language ?? this.language,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);
}