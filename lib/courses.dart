import 'package:hive/hive.dart';

part 'courses.g.dart'; // Needed for code generation

@HiveType(typeId: 0)
class Courses {
  @HiveField(0)
  String grade;

  @HiveField(1)
  int crdHrs;

  Courses({
    required this.grade,
    required this.crdHrs,
  });
}