import 'package:flutter/material.dart';
import 'app_theme.dart';

class LightTheme {
  LightTheme._();

  static final ColorScheme _colorScheme = ColorScheme.light(
    primary: const Color(0xFF0066FF),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE5F0FF),
    onPrimaryContainer: const Color(0xFF004FC7),
    
    secondary: const Color(0xFF00B686),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE5F8F3),
    onSecondaryContainer: const Color(0xFF008C67),
    
    error: const Color(0xFFDC3545),
    onError: Colors.white,
    errorContainer: const Color(0xFFFBE7E9),
    onErrorContainer: const Color(0xFFA42834),
    
    surface: const Color(0xFFF8F9FA),
    onSurface: const Color(0xFF1A1F36),
    
    surfaceContainer: Colors.white,
    surfaceContainerHighest: const Color(0xFFF8F9FA),
    onSurfaceVariant: const Color(0xFF44496A),
    
    outline: const Color(0xFFE2E8F0),
    outlineVariant: const Color(0xFFEDF2F7),
    
    shadow: Colors.black.withOpacity(0.1),
    scrim: Colors.black.withOpacity(0.3),
    
    inverseSurface: const Color(0xFF303030),
    onInverseSurface: Colors.white,
    inversePrimary: const Color(0xFF80B3FF),
    
    surfaceTint: const Color(0xFF0066FF),
  );

  static ThemeData get theme => AppTheme.buildTheme(
    brightness: Brightness.light,
    colorScheme: _colorScheme,
  );
}