import 'package:flutter/material.dart';
import '../../../data/models/budget/budget_model.dart';
import 'budget_list_view.dart';
import 'budget_detail_view.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({Key? key}) : super(key: key);

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const BudgetListView(),
    BudgetDetailView(budget: BudgetModel(
      id: '1',
      userId: 'user1',
      name: 'Sample Budget',
      amount: 1000.0,
      remainingAmount: 900.0,
      currency: 'USD',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 31),
      category: 'General',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      color: '#FF5733',
      recurrence: 'Monthly',
      notificationThreshold: 0.8,
      isActive: true,
      isExpired: false,
      description: 'Sample budget for testing',
      utilizationPercentage: 0.1,
    )),
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
            label: 'Budget List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budget Detail',
          ),
        ],
      ),
    );
  }
}
