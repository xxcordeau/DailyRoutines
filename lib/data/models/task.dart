import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? memo;

  @HiveField(3)
  bool isRequired;

  @HiveField(4)
  bool isRoutine;

  @HiveField(5)
  List<String> subItems;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  int order;

  Task({
    required this.id,
    required this.title,
    this.memo,
    this.isRequired = true,
    this.isRoutine = false,
    List<String>? subItems,
    DateTime? createdAt,
    this.order = 0,
  })  : subItems = subItems ?? [],
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? memo,
    bool? isRequired,
    bool? isRoutine,
    List<String>? subItems,
    DateTime? createdAt,
    int? order,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      isRequired: isRequired ?? this.isRequired,
      isRoutine: isRoutine ?? this.isRoutine,
      subItems: subItems ?? List.from(this.subItems),
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }
}
