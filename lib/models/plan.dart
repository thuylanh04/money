class Plan {
  final String id;
  final String name;
  final String period; // week | month | year
  final double budget;

  const Plan({
    required this.id,
    required this.name,
    required this.period,
    required this.budget,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      period: json['period'] as String,
      budget: (json['budget'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'period': period,
      'budget': budget,
    };
  }
}
