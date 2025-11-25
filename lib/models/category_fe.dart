class CategoryFE {
  final String idFE;
  final String categoryName;
  /// Backend currently uses string field `groupIdFE` to link to CategoryGroup.idFE.
  final String groupIdFE;

  CategoryFE({
    required this.idFE,
    required this.categoryName,
    required this.groupIdFE,
  });

  factory CategoryFE.fromJson(Map<String, dynamic> json) {
    // Accept both `groupIdFE` and numeric `groupId` (fallback, if any).
    String groupIdFE;
    if (json['groupIdFE'] is String) {
      groupIdFE = json['groupIdFE'] as String;
    } else if (json['groupId'] != null) {
      groupIdFE = json['groupId'].toString();
    } else {
      groupIdFE = '';
    }

    return CategoryFE(
      idFE: json['idFE'] as String,
      categoryName: json['categoryname'] as String,
      groupIdFE: groupIdFE,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFE': idFE,
      'categoryname': categoryName,
      'groupIdFE': groupIdFE,
    };
  }
}
