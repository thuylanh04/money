import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  static const String routeName = '/categories';

  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Expense', Icons.arrow_circle_down_outlined, AppTheme.primaryGreen),
      ('Income', Icons.arrow_circle_up_outlined, Colors.blueAccent),
    ];

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final (title, icon, color) = sections[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(title),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.fastfood_outlined),
                  title: Text('Food & Drinks'),
                ),
                const ListTile(
                  leading: Icon(Icons.directions_bus_outlined),
                  title: Text('Transport'),
                ),
                const ListTile(
                  leading: Icon(Icons.more_horiz),
                  title: Text('More categories'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
