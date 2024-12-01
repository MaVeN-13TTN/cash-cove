import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return width * 0.3; // 30% of screen width
    } else if (isTablet(context)) {
      return width * 0.45; // 45% of screen width
    }
    return width; // Full width on mobile
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(32.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(16.0);
  }
}
