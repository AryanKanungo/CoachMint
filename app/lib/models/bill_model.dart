class BillModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;

  BillModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  // Factory constructor to create a Bill from Supabase JSON
  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      // Parses the TEXT/ISO8601 date from DB
      dueDate: DateTime.parse(json['due_date']),
      isPaid: json['is_paid'] ?? false,
    );
  }

  // Converts the model back to JSON for Supabase updates
  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "name": name,
        "amount": amount,
        "due_date": dueDate.toIso8601String(),
        "is_paid": isPaid,
      };
}