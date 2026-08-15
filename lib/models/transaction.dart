import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 5)
enum TransactionType {
  @HiveField(0)
  deposit,
  @HiveField(1)
  withdrawal,
}

@HiveType(typeId: 6)
class Transaction extends HiveObject {
  @HiveField(0)
  TransactionType type;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? note;

  @HiveField(4)
  DateTime date;

  Transaction({
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
  });
}
