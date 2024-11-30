import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  // Date formatting
  String get formattedDate => DateFormat('MMM d, y').format(this);
  String get formattedDateTime => DateFormat('MMM d, y HH:mm').format(this);
  String get formattedTime => DateFormat('HH:mm').format(this);
  String get formattedMonthYear => DateFormat('MMMM y').format(this);
  
  // Budget period helpers
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0);
  DateTime get startOfYear => DateTime(year, 1, 1);
  DateTime get endOfYear => DateTime(year, 12, 31);
  
  // Fiscal year helpers (assuming fiscal year starts in April)
  DateTime get startOfFiscalYear => 
      month >= 4 ? DateTime(year, 4, 1) : DateTime(year - 1, 4, 1);
  DateTime get endOfFiscalYear =>
      month >= 4 ? DateTime(year + 1, 3, 31) : DateTime(year, 3, 31);
  
  // Budget comparison helpers
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
      
  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;
      
  bool isSameYear(DateTime other) => year == other.year;
  
  bool get isToday => isSameDay(DateTime.now());
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));
  
  // Period calculations
  int daysBetween(DateTime other) =>
      (difference(other).inHours / 24).round().abs();
      
  int monthsBetween(DateTime other) {
    return ((year - other.year) * 12 + month - other.month).abs();
  }
  
  // Budget period getters
  List<DateTime> getDaysInMonth() {
    final days = <DateTime>[];
    final firstDay = startOfMonth;
    final lastDay = endOfMonth;
    
    for (var i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    return days;
  }
  
  List<DateTime> getDaysInRange(DateTime endDate) {
    final days = <DateTime>[];
    var currentDate = this;
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      days.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return days;
  }
  
  // Relative time
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '$difference.inMinutes minutes ago';
    } else {
      return 'Just now';
    }
  }
  
  // Currency formatting with date
  String formatCurrency(double amount) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return '${currencyFormatter.format(amount)} on $formattedDate';
  }
}
