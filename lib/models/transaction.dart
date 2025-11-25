class Transaction {
  final String idFE;
  final double amount;
  final DateTime date;
  final String? note;
  final String? image;
  final String? categoryIdFE;
  final String? walletIdFE;

  const Transaction({
    required this.idFE,
    required this.amount,
    required this.date,
    this.note,
    this.image,
    this.categoryIdFE,
    this.walletIdFE,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      idFE: json['idFE'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      image: json['image'] as String?,
      categoryIdFE: json['categoryIdFE'] as String?,
      walletIdFE: json['walletIdFE'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFE': idFE,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'image': image,
      'categoryIdFE': categoryIdFE,
      'walletIdFE': walletIdFE,
    };
  }
  
  // Helper method to get the transaction type (expense/income) based on amount
  String get type => amount < 0 ? 'expense' : 'income';
  
  // Helper method to get the display amount (absolute value)
  double get displayAmount => amount.abs();
}
