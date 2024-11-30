import 'package:intl/intl.dart';

extension StringExtension on String {
  // Validation extensions
  bool get isEmail => RegExp(
        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
      ).hasMatch(this);
  
  bool get isPassword =>
      length >= 8 && RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(this);
  
  bool get isPhoneNumber =>
      RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(this);
  
  // Formatting extensions
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
  
  String get titleCase => split(' ')
      .map((word) => word.capitalize)
      .join(' ');
  
  String get initials => split(' ')
      .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
      .join();
      
  // Currency formatting
  String toCurrency({String symbol = '\$', int decimalDigits = 2}) {
    try {
      final number = double.parse(this);
      final formatter = NumberFormat.currency(
        symbol: symbol,
        decimalDigits: decimalDigits,
      );
      return formatter.format(number);
    } catch (e) {
      return this;
    }
  }
  
  // Date formatting
  String toFormattedDate({String format = 'MMM dd, yyyy'}) {
    try {
      final date = DateTime.parse(this);
      return DateFormat(format).format(date);
    } catch (e) {
      return this;
    }
  }
  
  // Time ago
  String get timeAgo {
    try {
      final date = DateTime.parse(this);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return this;
    }
  }
  
  // Truncate with ellipsis
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}...';
}
