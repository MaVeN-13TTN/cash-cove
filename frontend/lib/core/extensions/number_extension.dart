import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension NumExtension on num {
  // Currency formatting
  String toCurrency({
    String symbol = '\$',
    int decimalDigits = 2,
    String locale = 'en_US',
  }) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      locale: locale,
    );
    return formatter.format(this);
  }
  
  // Percentage formatting
  String toPercentage({int decimalDigits = 1}) {
    final formatter = NumberFormat.percentPattern()
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(this / 100);
  }
  
  // Compact number formatting (e.g., 1K, 1M)
  String toCompact({String locale = 'en_US'}) {
    final formatter = NumberFormat.compact(locale: locale);
    return formatter.format(this);
  }
  
  // Duration extensions
  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
  Duration get hours => Duration(hours: toInt());
  Duration get days => Duration(days: toInt());
  
  // Spacing extensions for UI
  Widget get horizontalSpace => SizedBox(width: toDouble());
  Widget get verticalSpace => SizedBox(height: toDouble());
  
  // Range validation
  bool isBetween(num start, num end) =>
      this >= start && this <= end;
      
  // Rounding extensions
  double roundTo(int places) {
    final mod = pow(10.0, places);
    return ((this * mod).round().toDouble() / mod);
  }
  
  // File size formatting
  String toFileSize() {
    if (this < 1024) return '${round()} B';
    if (this < 1024 * 1024) return '${(this / 1024).roundTo(1)} KB';
    if (this < 1024 * 1024 * 1024) return '${(this / (1024 * 1024)).roundTo(1)} MB';
    return '${(this / (1024 * 1024 * 1024)).roundTo(1)} GB';
  }
}

extension DoubleExtension on double {
  // Additional double-specific extensions
  bool get isWhole => this % 1 == 0;
  
  // Angle conversions
  double get toRadians => this * (pi / 180);
  double get toDegrees => this * (180 / pi);
}
