class CategoryFE {
  final String idFE;
  final String categoryName;
  final int groupId;

  CategoryFE({
    required this.idFE,
    required this.categoryName,
    required this.groupId,
  });

  factory CategoryFE.fromJson(Map<String, dynamic> json) {
    return CategoryFE(
      idFE: json['idFE'] as String,
      categoryName: json['categoryname'] as String,
      groupId: json['groupId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFE': idFE,
      'categoryname': categoryName,
      'groupId': groupId,
    };
  }
}
