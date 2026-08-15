import 'package:hive/hive.dart';

part 'payroll_slip.g.dart';

@HiveType(typeId: 4)
class PayrollSlip extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String imagePath;

  @HiveField(2)
  String? note;

  PayrollSlip({required this.date, required this.imagePath, this.note});
}
