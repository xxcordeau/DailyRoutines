import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 3)
class Goal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? subtitle;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    this.subtitle,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
