import 'package:drift/drift.dart';

@DataClassName('CreatorProfileEntity')
class CreatorProfile extends Table {
  IntColumn get internalId => integer().autoIncrement()(); // 全局唯一内部ID
  TextColumn get serviceId => text()(); // 服务标识
  TextColumn get id => text()(); // 服务内原始ID
  TextColumn get url => text()();
  TextColumn get name => text()();
  TextColumn get thumbnailUrl => text().nullable()();

  @override
  String get tableName => 'creator_profile';

  @override
  List<Set<Column>> get uniqueKeys => [
    {serviceId, id}, // 保证同一服务下ID唯一
  ];
}
