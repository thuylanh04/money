class Bill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool recurring;

  const Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.recurring,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      recurring: json['recurring'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'recurring': recurring,
    };
  }
}
