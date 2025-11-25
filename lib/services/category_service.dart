import '../models/category_fe.dart';
import '../services/api_client.dart';

class CategoryService {
  final ApiClient _client;

  CategoryService(this._client);

  /// Gọi API GET /api/v1/categories để lấy danh sách category
  /// với các trường: idFE, categoryname, groupIdFE.
  Future<List<CategoryFE>> fetchCategories() async {
    final data = await _client.get('/api/v1/categories');

    if (data == null) return <CategoryFE>[];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(CategoryFE.fromJson)
          .toList();
    }

    // Backend hiện trả dạng { "code": 1000, "result": [ ... ] }
    if (data is Map<String, dynamic>) {
      final result = data['result'];
      if (result is List) {
        return result
            .whereType<Map<String, dynamic>>()
            .map(CategoryFE.fromJson)
            .toList();
      }
      // Fallback nếu backend dùng key "data".
      if (data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CategoryFE.fromJson)
            .toList();
      }
    }

    return <CategoryFE>[];
  }
}
