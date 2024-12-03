part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const home = '/home';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const forgotPassword = '/auth/forgot-password';
  static const dashboard = '/dashboard';
  static const addExpense = '/expense/add';
  static const expenseList = '/expense/list';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const twoFactor = '/2fa-verification';
}
