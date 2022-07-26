import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 1)
class Todo {
  @HiveField(0)
  String title;
  @HiveField(1)
  String desc;
  @HiveField(2)
  String timing;
  @HiveField(3)
  String priority;

  Todo({required this.title, required this.desc, required this.timing, required this.priority});
}
