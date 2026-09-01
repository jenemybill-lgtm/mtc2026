import 'package:mtc2026/models/project_models.dart';

class CategoryBreakdown {
  final double labor;
  final double materials;
  final double agreed;
  final double total;
  final List<AttendanceEntity> laborRecords;
  final List<Expense> materialRecords;

  CategoryBreakdown({
    required this.labor,
    required this.materials,
    required this.agreed,
    required this.total,
    this.laborRecords = const [],
    this.materialRecords = const [],
  });
}
