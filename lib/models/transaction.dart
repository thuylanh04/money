// lib/models/transaction.dart
class Transaction {
  final String idFE;
  final double amount;
  final DateTime date;
  final String? note;
  final List<String>? image;
  final String? categoryIdFE;
  final String? walletIdFE;
  final String? categoryName;
  final String? walletName;
  final String? groupIdFE;
  final String? groupType;

  Transaction({
    required this.idFE,
    required this.amount,
    required this.date,
    this.note,
    this.image,
    this.categoryIdFE,
    this.walletIdFE,
    this.categoryName,
    this.walletName,
    this.groupIdFE,
    this.groupType,
  });

  Transaction copyWith({
    String? idFE,
    double? amount,
    DateTime? date,
    String? note,
    List<String>? image,
    String? categoryIdFE,
    String? walletIdFE,
    String? categoryName,
    String? walletName,
    String? groupIdFE,
    String? groupType,
  }) {
    return Transaction(
      idFE: idFE ?? this.idFE,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      image: image ?? this.image,
      categoryIdFE: categoryIdFE ?? this.categoryIdFE,
      walletIdFE: walletIdFE ?? this.walletIdFE,
      categoryName: categoryName ?? this.categoryName,
      walletName: walletName ?? this.walletName,
      groupIdFE: groupIdFE ?? this.groupIdFE,
      groupType: groupType ?? this.groupType,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Extract category name from categoryIdFE (format: 'Name...')
    String? extractName(String? idFE) {
      if (idFE == null) return null;
      // Extract the name part before the date string
      final dateIndex = idFE.indexOf(
          RegExp(r'[A-Za-z]{3} [A-Za-z]{3} \d{1,2} \d{2}:\d{2}:\d{2}'));
      return dateIndex > 0 ? idFE.substring(0, dateIndex).trim() : idFE;
    }

    // Ensure amount is always positive
    final amount = ((json['amount'] as num?)?.toDouble() ?? 0.0).abs();

    return Transaction(
      idFE: json['idFE']?.toString() ?? '',
      amount: amount,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note']?.toString(),
      image: () {
        final raw = json['image'];
        if (raw == null) return null;
        if (raw is List) {
          return raw
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
        final s = raw.toString();
        return s.isEmpty ? null : <String>[s];
      }(),
      categoryIdFE: json['categoryIdFE']?.toString(),
      walletIdFE: json['walletIdFE']?.toString(),
      categoryName: extractName(json['categoryIdFE']?.toString()),
      walletName: extractName(json['walletIdFE']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFE': idFE,
      'amount': amount,
      'date': date.toIso8601String(),
      if (note != null) 'note': note,
      if (image != null) 'image': image,
      if (categoryIdFE != null) 'categoryIdFE': categoryIdFE,
      if (walletIdFE != null) 'walletIdFE': walletIdFE,
    };
  }
}
