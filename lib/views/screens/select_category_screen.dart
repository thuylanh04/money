import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/category_list_item.dart';

class SelectCategoryScreen extends StatefulWidget {
  static const String routeName = '/select-category';

  const SelectCategoryScreen({super.key});

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late List<String> _expenseCategories;
  late List<String> _incomeCategories;
  late List<String> _debtCategories;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _expenseCategories = List<String>.from(expenseCategories);
    _incomeCategories = List<String>.from(incomeCategories);
    _debtCategories = List<String>.from(debtCategories);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Select category'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'EXPENSE'),
            Tab(text: 'INCOME'),
            Tab(text: 'DEBT/LOAN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(_expenseCategories),
          _CategoryList(_incomeCategories),
          _CategoryList(_debtCategories),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  Navigator.of(context).pop();
                  return;
                }
                setState(() {
                  switch (_tabController.index) {
                    case 0:
                      _expenseCategories.add(name);
                      break;
                    case 1:
                      _incomeCategories.add(name);
                      break;
                    case 2:
                      _debtCategories.add(name);
                      break;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<String> items;

  const _CategoryList(this.items);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final title = items[index];
        return CategoryListItem(
          title: title,
          icon: Icons.category_outlined, // icon phỏng đoán
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: items.length,
    );
  }
}

// Mock categories, phỏng đoán dựa trên screenshot.
const expenseCategories = <String>[
  'Bills & Utilities',
  'Electricity Bill',
  'Gas Bill',
  'Education',
  'Entertainment',
  'Food & Beverage',
  'Health & Fitness',
  'Medical Checkup',
  'Insurance',
  'Investment',
  'Shopping',
  'Houseware',
  'Transportation',
];

const incomeCategories = <String>[
  'Collect Interest',
  'Incoming transfer',
  'Other Income',
  'Salary',
];

const debtCategories = <String>[
  'Debt',
  'Debt Collection',
  'Loan',
  'Repayment',
];
