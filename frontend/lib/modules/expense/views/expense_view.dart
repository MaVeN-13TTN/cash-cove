import 'package:flutter/material.dart';
import 'expense_list_view.dart';
import 'add_expense_view.dart';

class ExpenseView extends StatefulWidget {
  const ExpenseView({Key? key}) : super(key: key);

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const ExpenseListView(),
    const AddExpenseView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _views[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Expense List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Expense',
          ),
        ],
      ),
    );
  }
}
