class TransactionRequest {
  final String idFE;
  final String categoryIdFE;
  final String walletIdFE;
  final double amount;
  final DateTime date;
  final String note;
  final String image;

  TransactionRequest({
    required this.idFE,
    required this.categoryIdFE,
    required this.walletIdFE,
    required this.amount,
    required this.date,
    required this.note,
    required this.image,
  });

  Map<String, dynamic> toJson() {
    return {
      'idFE': idFE,
      'categoryIdFE': categoryIdFE,
      'walletIdFE': walletIdFE,
      'amount': amount,
      // Gửi date dạng ISO, backend có thể parse hoặc bạn đổi sang yyyy-MM-dd nếu cần
      'date': date.toIso8601String(),
      'note': note,
      'image': image,
    };
  }
}
