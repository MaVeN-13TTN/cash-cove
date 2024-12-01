import 'package:flutter/material.dart';

class AnimationUtils {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;

  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.fromBottom,
  }) {
    final Tween<Offset> offsetTween = direction == SlideDirection.fromBottom
        ? Tween(begin: const Offset(0, 1), end: Offset.zero)
        : Tween(begin: const Offset(-1, 0), end: Offset.zero);

    return SlideTransition(
      position: animation.drive(offsetTween),
      child: child,
    );
  }
}

enum SlideDirection {
  fromBottom,
  fromLeft,
}
