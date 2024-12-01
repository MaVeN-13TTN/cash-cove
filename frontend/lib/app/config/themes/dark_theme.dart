import 'package:flutter/material.dart';
import 'app_theme.dart';

class DarkTheme {
  DarkTheme._();

  static final ColorScheme _colorScheme = ColorScheme.dark(
    primary: const Color(0xFF409CFF),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF004FC7),
    onPrimaryContainer: const Color(0xFFE5F0FF),
    
    secondary: const Color(0xFF00E6A8),
    onSecondary: Colors.black,
    secondaryContainer: const Color(0xFF008C67),
    onSecondaryContainer: const Color(0xFFE5F8F3),
    
    error: const Color(0xFFFF4D5E),
    onError: Colors.white,
    errorContainer: const Color(0xFFA42834),
    onErrorContainer: const Color(0xFFFBE7E9),
    
    surface: const Color(0xFF121212),
    onSurface: const Color(0xFFE9ECEF),
    
    surfaceContainer: const Color(0xFF1E1E1E),
    surfaceContainerHighest: const Color(0xFF2C2C2C),
    onSurfaceVariant: const Color(0xFFBEC2C6),
    
    outline: const Color(0xFF3E3E3E),
    outlineVariant: const Color(0xFF2C2C2C),
    
    shadow: Colors.black.withOpacity(0.2),
    scrim: Colors.black.withOpacity(0.4),
    
    inverseSurface: const Color(0xFFF8F9FA),
    onInverseSurface: const Color(0xFF1A1F36),
    inversePrimary: const Color(0xFF0066FF),
    
    surfaceTint: const Color(0xFF409CFF),
  );

  static ThemeData get theme => AppTheme.buildTheme(
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
  );
}