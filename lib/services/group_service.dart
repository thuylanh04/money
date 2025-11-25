import '../models/category_group.dart';
import '../services/api_client.dart';

class GroupService {
  final ApiClient _client;

  GroupService(this._client);

  /// GET /api/v1/groups to fetch high-level groups (Expense, Income, Debt,...)
  Future<List<CategoryGroup>> fetchGroups() async {
    final data = await _client.get('/api/v1/groups');
    if (data == null || data is! Map<String, dynamic>) {
      return <CategoryGroup>[];
    }

    final result = data['result'];
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(CategoryGroup.fromJson)
          .toList();
    }

    return <CategoryGroup>[];
  }
}
