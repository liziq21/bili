import 'package:drift/drift.dart';

@DataClassName('MediaEntity')
class Media extends Table {
  static const String typeVideo = 'video';
  static const String typeArticle = 'article';
  static const String typePost = 'post';

  IntColumn get internalId => integer().autoIncrement()(); // 全局唯一ID
  TextColumn get sourceId => text()(); // 来源标识
  TextColumn get originalId => text()(); // 原始ID
  TextColumn get title => text()(); // 标题
  TextColumn get url => text()(); // 媒体页面URL
  TextColumn get thumbnailUrl => text().nullable()(); // 缩略图/封面URL
  TextColumn get creatorProfileName => text().nullable()();
  TextColumn get creatorProfileId => text().nullable()();
  DateTimeColumn get uploadDate => dateTime().nullable()(); // 发布日期

  TextColumn get type => text()();

  @override
  String get tableName => 'media';

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceId, type, originalId}, // 同一来源内原始ID唯一
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (type IN ('video', 'article', 'post'))",
  ];
}
