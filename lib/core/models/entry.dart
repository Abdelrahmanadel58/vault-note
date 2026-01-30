import 'package:hive/hive.dart';

part 'entry.g.dart';

@HiveType(typeId: 0)
class VaultEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? usernameOrEmail;

  @HiveField(3)
  String? password;

  @HiveField(4)
  String? note;

  @HiveField(5)
  String category;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  VaultEntry({
    required this.id,
    required this.title,
    this.usernameOrEmail,
    this.password,
    this.note,
    this.category = 'Other',
    required this.createdAt,
    this.updatedAt,
  });
}