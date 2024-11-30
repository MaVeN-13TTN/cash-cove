import 'package:flutter/material.dart';

extension WidgetExtension on Widget {
  // Padding helpers
  Widget paddingAll(double padding) => Padding(
        padding: EdgeInsets.all(padding),
        child: this,
      );
      
  Widget paddingSymmetric({
    double horizontal = 0.0,
    double vertical = 0.0,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );
      
  Widget paddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        child: this,
      );
  
  // Alignment helpers
  Widget get center => Center(child: this);
  Widget get alignLeft => Align(
        alignment: Alignment.centerLeft,
        child: this,
      );
  Widget get alignRight => Align(
        alignment: Alignment.centerRight,
        child: this,
      );
  
  // Container wrappers
  Widget withBackground(Color color) => Container(
        color: color,
        child: this,
      );
        
  Widget withDecoration(BoxDecoration decoration) => Container(
        decoration: decoration,
        child: this,
      );
  
  // Size constraints
  Widget constrained({
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) =>
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
          minWidth: minWidth ?? 0.0,
          minHeight: minHeight ?? 0.0,
        ),
        child: this,
      );
  
  // Responsive helpers
  Widget expanded([int flex = 1]) => Expanded(
        flex: flex,
        child: this,
      );
  
  Widget flexible([int flex = 1, FlexFit fit = FlexFit.loose]) => Flexible(
        flex: flex,
        fit: fit,
        child: this,
      );
  
  // Gesture detectors
  Widget onTap(VoidCallback action) => GestureDetector(
        onTap: action,
        child: this,
      );
        
  Widget onLongPress(VoidCallback action) => GestureDetector(
        onLongPress: action,
        child: this,
      );
  
  // Animation wrappers
  Widget animate({
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) =>
      AnimatedSwitcher(
        duration: duration,
        switchInCurve: curve,
        switchOutCurve: curve,
        child: this,
      );
  
  // Visibility helpers
  Widget visible(bool visible) => Visibility(
        visible: visible,
        child: this,
      );
        
  Widget opacity(double opacity) => Opacity(
        opacity: opacity,
        child: this,
      );
  
  // Card wrapper
  Widget card({
    double? elevation,
    Color? color,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) =>
      Card(
        elevation: elevation,
        color: color,
        shape: borderRadius != null
            ? RoundedRectangleBorder(borderRadius: borderRadius)
            : null,
        child: padding != null
            ? Padding(padding: padding, child: this)
            : this,
      );
  
  // Tooltip wrapper
  Widget tooltip(String message) => Tooltip(
        message: message,
        child: this,
      );
  
  // Hero animation
  Widget hero(String tag) => Hero(
        tag: tag,
        child: this,
      );
}
