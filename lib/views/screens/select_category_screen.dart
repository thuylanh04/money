import 'package:flutter/material.dart';

import '../../models/category_fe.dart';
import '../../models/category_group.dart';
import '../../services/api_client.dart';
import '../../services/category_service.dart';
import '../../services/group_service.dart';
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
  late final CategoryService _categoryService;
  late final GroupService _groupService;
  List<CategoryFE> _expenseCategories = <CategoryFE>[];
  List<CategoryFE> _incomeCategories = <CategoryFE>[];
  List<CategoryFE> _debtCategories = <CategoryFE>[];
  List<CategoryGroup> _groups = <CategoryGroup>[];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _categoryService = CategoryService(ApiClient());
    _groupService = GroupService(ApiClient());
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseLabel = _groups.isNotEmpty ? _groups[0].groupName : 'EXPENSE';
    final incomeLabel =
        _groups.length > 1 ? _groups[1].groupName : 'INCOME';
    final debtLabel =
        _groups.length > 2 ? _groups[2].groupName : 'DEBT/LOAN';
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
          tabs: [
            Tab(text: expenseLabel.toUpperCase()),
            Tab(text: incomeLabel.toUpperCase()),
            Tab(text: debtLabel.toUpperCase()),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _CategoryList(_expenseCategories),
                    _CategoryList(_incomeCategories),
                    _CategoryList(_debtCategories),
                  ],
                ),
    );
  }

  Future<void> _loadData() async {
    try {
      final groups = await _groupService.fetchGroups();
      final categories = await _categoryService.fetchCategories();
      setState(() {
        _groups = groups;

        String? expenseIdFE;
        String? incomeIdFE;
        String? debtIdFE;
        if (groups.isNotEmpty) expenseIdFE = groups[0].idFE;
        if (groups.length > 1) incomeIdFE = groups[1].idFE;
        if (groups.length > 2) debtIdFE = groups[2].idFE;

        _expenseCategories = categories
            .where((c) => expenseIdFE != null && c.groupIdFE == expenseIdFE)
            .toList(growable: true);
        _incomeCategories = categories
            .where((c) => incomeIdFE != null && c.groupIdFE == incomeIdFE)
            .toList(growable: true);
        _debtCategories = categories
            .where((c) => debtIdFE != null && c.groupIdFE == debtIdFE)
            .toList(growable: true);

        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load categories: ${e.toString()}';
      });
    }
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
                  final id = 'local-${DateTime.now().millisecondsSinceEpoch}';
                  String expenseIdFE =
                      _groups.isNotEmpty ? _groups[0].idFE : 'expense-local';
                  String incomeIdFE =
                      _groups.length > 1 ? _groups[1].idFE : 'income-local';
                  String debtIdFE =
                      _groups.length > 2 ? _groups[2].idFE : 'debt-local';
                  switch (_tabController.index) {
                    case 0:
                      _expenseCategories.add(
                        CategoryFE(
                          idFE: id,
                          categoryName: name,
                          groupIdFE: expenseIdFE,
                        ),
                      );
                      break;
                    case 1:
                      _incomeCategories.add(
                        CategoryFE(
                          idFE: id,
                          categoryName: name,
                          groupIdFE: incomeIdFE,
                        ),
                      );
                      break;
                    case 2:
                      _debtCategories.add(
                        CategoryFE(
                          idFE: id,
                          categoryName: name,
                          groupIdFE: debtIdFE,
                        ),
                      );
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
  final List<CategoryFE> items;

  const _CategoryList(this.items);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return CategoryListItem(
          title: item.categoryName,
          icon: Icons.category_outlined, // icon phỏng đoán
          onTap: () {
            Navigator.of(context).pop<CategoryFE>(item);
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: items.length,
    );
  }
}
