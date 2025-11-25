import 'package:flutter/material.dart';

import '../../models/category_fe.dart';
import '../../models/category_group.dart';
import '../../services/api_client.dart';
import '../../services/category_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  static const String routeName = '/categories';

  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final GroupService _groupService;
  late final CategoryService _categoryService;
  List<CategoryGroup> _groups = <CategoryGroup>[];
  List<CategoryFE> _categories = <CategoryFE>[];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    _groupService = GroupService(client);
    _categoryService = CategoryService(client);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final groups = await _groupService.fetchGroups();
      final categories = await _categoryService.fetchCategories();
      setState(() {
        _groups = groups;
        _categories = categories;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Add category'),
                    content: const Text('This is a placeholder to add a new category.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    final groupCategories = _categories
                        .where((c) => c.groupIdFE == group.idFE)
                        .toList();

                    final (icon, color) = _iconForGroup(index);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(icon, color: color),
                            title: Text(group.groupName),
                          ),
                          const Divider(height: 1),
                          if (groupCategories.isEmpty)
                            const ListTile(
                              title: Text('No categories'),
                            )
                          else
                            ...groupCategories.map(
                              (c) => ListTile(
                                leading: const Icon(Icons.category_outlined),
                                title: Text(c.categoryName),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  (IconData, Color) _iconForGroup(int index) {
    if (index == 0) {
      return (Icons.arrow_circle_down_outlined, AppTheme.primaryGreen);
    }
    if (index == 1) {
      return (Icons.arrow_circle_up_outlined, Colors.blueAccent);
    }
    return (Icons.sync_alt_outlined, Colors.orangeAccent);
  }
}
