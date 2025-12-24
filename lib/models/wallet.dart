class Wallet {
  final String idFE;
  final String walletName;

  Wallet({
    required this.idFE,
    required this.walletName,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      idFE: json['idFE'] ?? '',
      walletName: json['walletName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFE': idFE,
      'walletName': walletName,
    };
  }
}
