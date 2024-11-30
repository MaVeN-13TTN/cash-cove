import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;
  final Color info;

  const AppColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  static const light = AppColors(
    success: Color(0xFF28A745),
    warning: Color(0xFFFFC107),
    info: Color(0xFF17A2B8),
  );

  static const dark = AppColors(
    success: Color(0xFF2FB344),
    warning: Color(0xFFFFCA2C),
    info: Color(0xFF0DCAF0),
  );
}
