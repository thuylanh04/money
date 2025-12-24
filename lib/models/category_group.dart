class CategoryGroup {
  final String idFE;
  final String groupName;

  CategoryGroup({
    required this.idFE,
    required this.groupName,
  });

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    return CategoryGroup(
      idFE: json['idFE'] as String,
      groupName: json['groupName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFE': idFE,
      'groupName': groupName,
    };
  }
}
