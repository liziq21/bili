// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_dao.dart';

// ignore_for_file: type=lint
mixin _$ArticleDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaTable get media => attachedDatabase.media;
  $ArticleTable get article => attachedDatabase.article;
  ArticleDaoManager get managers => ArticleDaoManager(this);
}

class ArticleDaoManager {
  final _$ArticleDaoMixin _db;
  ArticleDaoManager(this._db);
  $$MediaTableTableManager get media =>
      $$MediaTableTableManager(_db.attachedDatabase, _db.media);
  $$ArticleTableTableManager get article =>
      $$ArticleTableTableManager(_db.attachedDatabase, _db.article);
}
