// lib/models/transaction.dart
class Transaction {
  final String idFE;
  final double amount;
  final DateTime date;
  final String? note;
  final String? image;
  final String? categoryIdFE;
  final String? walletIdFE;
  final String? categoryName;
  final String? walletName;

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
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Extract category name from categoryIdFE (format: 'Name...')
    String? extractName(String? idFE) {
      if (idFE == null) return null;
      // Extract the name part before the date string
      final dateIndex = idFE.indexOf(RegExp(r'[A-Za-z]{3} [A-Za-z]{3} \d{1,2} \d{2}:\d{2}:\d{2}'));
      return dateIndex > 0 ? idFE.substring(0, dateIndex).trim() : idFE;
    }

    return Transaction(
      idFE: json['idFE']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null 
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note']?.toString(),
      image: json['image']?.toString(),
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