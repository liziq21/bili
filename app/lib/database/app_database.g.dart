// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RecentSearchQueryTable extends RecentSearchQuery
    with TableInfo<$RecentSearchQueryTable, RecentSearchQueryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentSearchQueryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queriedDateMeta = const VerificationMeta(
    'queriedDate',
  );
  @override
  late final GeneratedColumn<DateTime> queriedDate = GeneratedColumn<DateTime>(
    'queried_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [query, queriedDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_search_query';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentSearchQueryEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('queried_date')) {
      context.handle(
        _queriedDateMeta,
        queriedDate.isAcceptableOrUnknown(
          data['queried_date']!,
          _queriedDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  RecentSearchQueryEntity map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentSearchQueryEntity(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      queriedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queried_date'],
      )!,
    );
  }

  @override
  $RecentSearchQueryTable createAlias(String alias) {
    return $RecentSearchQueryTable(attachedDatabase, alias);
  }
}

class RecentSearchQueryEntity extends DataClass
    implements Insertable<RecentSearchQueryEntity> {
  final String query;
  final DateTime queriedDate;
  const RecentSearchQueryEntity({
    required this.query,
    required this.queriedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['queried_date'] = Variable<DateTime>(queriedDate);
    return map;
  }

  RecentSearchQueryCompanion toCompanion(bool nullToAbsent) {
    return RecentSearchQueryCompanion(
      query: Value(query),
      queriedDate: Value(queriedDate),
    );
  }

  factory RecentSearchQueryEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentSearchQueryEntity(
      query: serializer.fromJson<String>(json['query']),
      queriedDate: serializer.fromJson<DateTime>(json['queriedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'queriedDate': serializer.toJson<DateTime>(queriedDate),
    };
  }

  RecentSearchQueryEntity copyWith({String? query, DateTime? queriedDate}) =>
      RecentSearchQueryEntity(
        query: query ?? this.query,
        queriedDate: queriedDate ?? this.queriedDate,
      );
  RecentSearchQueryEntity copyWithCompanion(RecentSearchQueryCompanion data) {
    return RecentSearchQueryEntity(
      query: data.query.present ? data.query.value : this.query,
      queriedDate: data.queriedDate.present
          ? data.queriedDate.value
          : this.queriedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentSearchQueryEntity(')
          ..write('query: $query, ')
          ..write('queriedDate: $queriedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, queriedDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentSearchQueryEntity &&
          other.query == this.query &&
          other.queriedDate == this.queriedDate);
}

class RecentSearchQueryCompanion
    extends UpdateCompanion<RecentSearchQueryEntity> {
  final Value<String> query;
  final Value<DateTime> queriedDate;
  final Value<int> rowid;
  const RecentSearchQueryCompanion({
    this.query = const Value.absent(),
    this.queriedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentSearchQueryCompanion.insert({
    required String query,
    this.queriedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : query = Value(query);
  static Insertable<RecentSearchQueryEntity> custom({
    Expression<String>? query,
    Expression<DateTime>? queriedDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (queriedDate != null) 'queried_date': queriedDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentSearchQueryCompanion copyWith({
    Value<String>? query,
    Value<DateTime>? queriedDate,
    Value<int>? rowid,
  }) {
    return RecentSearchQueryCompanion(
      query: query ?? this.query,
      queriedDate: queriedDate ?? this.queriedDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (queriedDate.present) {
      map['queried_date'] = Variable<DateTime>(queriedDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentSearchQueryCompanion(')
          ..write('query: $query, ')
          ..write('queriedDate: $queriedDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaTable extends Media with TableInfo<$MediaTable, MediaEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _internalIdMeta = const VerificationMeta(
    'internalId',
  );
  @override
  late final GeneratedColumn<int> internalId = GeneratedColumn<int>(
    'internal_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalIdMeta = const VerificationMeta(
    'originalId',
  );
  @override
  late final GeneratedColumn<String> originalId = GeneratedColumn<String>(
    'original_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorProfileNameMeta =
      const VerificationMeta('creatorProfileName');
  @override
  late final GeneratedColumn<String> creatorProfileName =
      GeneratedColumn<String>(
        'creator_profile_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creatorProfileIdMeta = const VerificationMeta(
    'creatorProfileId',
  );
  @override
  late final GeneratedColumn<String> creatorProfileId = GeneratedColumn<String>(
    'creator_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadDateMeta = const VerificationMeta(
    'uploadDate',
  );
  @override
  late final GeneratedColumn<DateTime> uploadDate = GeneratedColumn<DateTime>(
    'upload_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    internalId,
    sourceId,
    originalId,
    title,
    url,
    thumbnailUrl,
    creatorProfileName,
    creatorProfileId,
    uploadDate,
    type,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('internal_id')) {
      context.handle(
        _internalIdMeta,
        internalId.isAcceptableOrUnknown(data['internal_id']!, _internalIdMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('original_id')) {
      context.handle(
        _originalIdMeta,
        originalId.isAcceptableOrUnknown(data['original_id']!, _originalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_originalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('creator_profile_name')) {
      context.handle(
        _creatorProfileNameMeta,
        creatorProfileName.isAcceptableOrUnknown(
          data['creator_profile_name']!,
          _creatorProfileNameMeta,
        ),
      );
    }
    if (data.containsKey('creator_profile_id')) {
      context.handle(
        _creatorProfileIdMeta,
        creatorProfileId.isAcceptableOrUnknown(
          data['creator_profile_id']!,
          _creatorProfileIdMeta,
        ),
      );
    }
    if (data.containsKey('upload_date')) {
      context.handle(
        _uploadDateMeta,
        uploadDate.isAcceptableOrUnknown(data['upload_date']!, _uploadDateMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {internalId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, type, originalId},
  ];
  @override
  MediaEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaEntity(
      internalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}internal_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      originalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      creatorProfileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_profile_name'],
      ),
      creatorProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_profile_id'],
      ),
      uploadDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}upload_date'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $MediaTable createAlias(String alias) {
    return $MediaTable(attachedDatabase, alias);
  }
}

class MediaEntity extends DataClass implements Insertable<MediaEntity> {
  final int internalId;
  final String sourceId;
  final String originalId;
  final String title;
  final String url;
  final String? thumbnailUrl;
  final String? creatorProfileName;
  final String? creatorProfileId;
  final DateTime? uploadDate;
  final String type;
  const MediaEntity({
    required this.internalId,
    required this.sourceId,
    required this.originalId,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.creatorProfileName,
    this.creatorProfileId,
    this.uploadDate,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['internal_id'] = Variable<int>(internalId);
    map['source_id'] = Variable<String>(sourceId);
    map['original_id'] = Variable<String>(originalId);
    map['title'] = Variable<String>(title);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || creatorProfileName != null) {
      map['creator_profile_name'] = Variable<String>(creatorProfileName);
    }
    if (!nullToAbsent || creatorProfileId != null) {
      map['creator_profile_id'] = Variable<String>(creatorProfileId);
    }
    if (!nullToAbsent || uploadDate != null) {
      map['upload_date'] = Variable<DateTime>(uploadDate);
    }
    map['type'] = Variable<String>(type);
    return map;
  }

  MediaCompanion toCompanion(bool nullToAbsent) {
    return MediaCompanion(
      internalId: Value(internalId),
      sourceId: Value(sourceId),
      originalId: Value(originalId),
      title: Value(title),
      url: Value(url),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      creatorProfileName: creatorProfileName == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorProfileName),
      creatorProfileId: creatorProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorProfileId),
      uploadDate: uploadDate == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadDate),
      type: Value(type),
    );
  }

  factory MediaEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaEntity(
      internalId: serializer.fromJson<int>(json['internalId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      originalId: serializer.fromJson<String>(json['originalId']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String>(json['url']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      creatorProfileName: serializer.fromJson<String?>(
        json['creatorProfileName'],
      ),
      creatorProfileId: serializer.fromJson<String?>(json['creatorProfileId']),
      uploadDate: serializer.fromJson<DateTime?>(json['uploadDate']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'internalId': serializer.toJson<int>(internalId),
      'sourceId': serializer.toJson<String>(sourceId),
      'originalId': serializer.toJson<String>(originalId),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String>(url),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'creatorProfileName': serializer.toJson<String?>(creatorProfileName),
      'creatorProfileId': serializer.toJson<String?>(creatorProfileId),
      'uploadDate': serializer.toJson<DateTime?>(uploadDate),
      'type': serializer.toJson<String>(type),
    };
  }

  MediaEntity copyWith({
    int? internalId,
    String? sourceId,
    String? originalId,
    String? title,
    String? url,
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<String?> creatorProfileName = const Value.absent(),
    Value<String?> creatorProfileId = const Value.absent(),
    Value<DateTime?> uploadDate = const Value.absent(),
    String? type,
  }) => MediaEntity(
    internalId: internalId ?? this.internalId,
    sourceId: sourceId ?? this.sourceId,
    originalId: originalId ?? this.originalId,
    title: title ?? this.title,
    url: url ?? this.url,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    creatorProfileName: creatorProfileName.present
        ? creatorProfileName.value
        : this.creatorProfileName,
    creatorProfileId: creatorProfileId.present
        ? creatorProfileId.value
        : this.creatorProfileId,
    uploadDate: uploadDate.present ? uploadDate.value : this.uploadDate,
    type: type ?? this.type,
  );
  MediaEntity copyWithCompanion(MediaCompanion data) {
    return MediaEntity(
      internalId: data.internalId.present
          ? data.internalId.value
          : this.internalId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      originalId: data.originalId.present
          ? data.originalId.value
          : this.originalId,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      creatorProfileName: data.creatorProfileName.present
          ? data.creatorProfileName.value
          : this.creatorProfileName,
      creatorProfileId: data.creatorProfileId.present
          ? data.creatorProfileId.value
          : this.creatorProfileId,
      uploadDate: data.uploadDate.present
          ? data.uploadDate.value
          : this.uploadDate,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaEntity(')
          ..write('internalId: $internalId, ')
          ..write('sourceId: $sourceId, ')
          ..write('originalId: $originalId, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('creatorProfileName: $creatorProfileName, ')
          ..write('creatorProfileId: $creatorProfileId, ')
          ..write('uploadDate: $uploadDate, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    internalId,
    sourceId,
    originalId,
    title,
    url,
    thumbnailUrl,
    creatorProfileName,
    creatorProfileId,
    uploadDate,
    type,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaEntity &&
          other.internalId == this.internalId &&
          other.sourceId == this.sourceId &&
          other.originalId == this.originalId &&
          other.title == this.title &&
          other.url == this.url &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.creatorProfileName == this.creatorProfileName &&
          other.creatorProfileId == this.creatorProfileId &&
          other.uploadDate == this.uploadDate &&
          other.type == this.type);
}

class MediaCompanion extends UpdateCompanion<MediaEntity> {
  final Value<int> internalId;
  final Value<String> sourceId;
  final Value<String> originalId;
  final Value<String> title;
  final Value<String> url;
  final Value<String?> thumbnailUrl;
  final Value<String?> creatorProfileName;
  final Value<String?> creatorProfileId;
  final Value<DateTime?> uploadDate;
  final Value<String> type;
  const MediaCompanion({
    this.internalId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.originalId = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.creatorProfileName = const Value.absent(),
    this.creatorProfileId = const Value.absent(),
    this.uploadDate = const Value.absent(),
    this.type = const Value.absent(),
  });
  MediaCompanion.insert({
    this.internalId = const Value.absent(),
    required String sourceId,
    required String originalId,
    required String title,
    required String url,
    this.thumbnailUrl = const Value.absent(),
    this.creatorProfileName = const Value.absent(),
    this.creatorProfileId = const Value.absent(),
    this.uploadDate = const Value.absent(),
    required String type,
  }) : sourceId = Value(sourceId),
       originalId = Value(originalId),
       title = Value(title),
       url = Value(url),
       type = Value(type);
  static Insertable<MediaEntity> custom({
    Expression<int>? internalId,
    Expression<String>? sourceId,
    Expression<String>? originalId,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? thumbnailUrl,
    Expression<String>? creatorProfileName,
    Expression<String>? creatorProfileId,
    Expression<DateTime>? uploadDate,
    Expression<String>? type,
  }) {
    return RawValuesInsertable({
      if (internalId != null) 'internal_id': internalId,
      if (sourceId != null) 'source_id': sourceId,
      if (originalId != null) 'original_id': originalId,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (creatorProfileName != null)
        'creator_profile_name': creatorProfileName,
      if (creatorProfileId != null) 'creator_profile_id': creatorProfileId,
      if (uploadDate != null) 'upload_date': uploadDate,
      if (type != null) 'type': type,
    });
  }

  MediaCompanion copyWith({
    Value<int>? internalId,
    Value<String>? sourceId,
    Value<String>? originalId,
    Value<String>? title,
    Value<String>? url,
    Value<String?>? thumbnailUrl,
    Value<String?>? creatorProfileName,
    Value<String?>? creatorProfileId,
    Value<DateTime?>? uploadDate,
    Value<String>? type,
  }) {
    return MediaCompanion(
      internalId: internalId ?? this.internalId,
      sourceId: sourceId ?? this.sourceId,
      originalId: originalId ?? this.originalId,
      title: title ?? this.title,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      creatorProfileName: creatorProfileName ?? this.creatorProfileName,
      creatorProfileId: creatorProfileId ?? this.creatorProfileId,
      uploadDate: uploadDate ?? this.uploadDate,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (internalId.present) {
      map['internal_id'] = Variable<int>(internalId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (originalId.present) {
      map['original_id'] = Variable<String>(originalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (creatorProfileName.present) {
      map['creator_profile_name'] = Variable<String>(creatorProfileName.value);
    }
    if (creatorProfileId.present) {
      map['creator_profile_id'] = Variable<String>(creatorProfileId.value);
    }
    if (uploadDate.present) {
      map['upload_date'] = Variable<DateTime>(uploadDate.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCompanion(')
          ..write('internalId: $internalId, ')
          ..write('sourceId: $sourceId, ')
          ..write('originalId: $originalId, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('creatorProfileName: $creatorProfileName, ')
          ..write('creatorProfileId: $creatorProfileId, ')
          ..write('uploadDate: $uploadDate, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $MediaHistoryTable extends MediaHistory
    with TableInfo<$MediaHistoryTable, MediaHistoryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _internalIdMeta = const VerificationMeta(
    'internalId',
  );
  @override
  late final GeneratedColumn<int> internalId = GeneratedColumn<int>(
    'internal_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media (internal_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _accessedAtMeta = const VerificationMeta(
    'accessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> accessedAt = GeneratedColumn<DateTime>(
    'accessed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _progressSecondsMeta = const VerificationMeta(
    'progressSeconds',
  );
  @override
  late final GeneratedColumn<BigInt> progressSeconds = GeneratedColumn<BigInt>(
    'progress_seconds',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    internalId,
    mediaId,
    accessedAt,
    progressSeconds,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaHistoryEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('internal_id')) {
      context.handle(
        _internalIdMeta,
        internalId.isAcceptableOrUnknown(data['internal_id']!, _internalIdMeta),
      );
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('accessed_at')) {
      context.handle(
        _accessedAtMeta,
        accessedAt.isAcceptableOrUnknown(data['accessed_at']!, _accessedAtMeta),
      );
    }
    if (data.containsKey('progress_seconds')) {
      context.handle(
        _progressSecondsMeta,
        progressSeconds.isAcceptableOrUnknown(
          data['progress_seconds']!,
          _progressSecondsMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {internalId};
  @override
  MediaHistoryEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaHistoryEntity(
      internalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}internal_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      accessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accessed_at'],
      )!,
      progressSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}progress_seconds'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $MediaHistoryTable createAlias(String alias) {
    return $MediaHistoryTable(attachedDatabase, alias);
  }
}

class MediaHistoryEntity extends DataClass
    implements Insertable<MediaHistoryEntity> {
  final int internalId;
  final int mediaId;
  final DateTime accessedAt;
  final BigInt? progressSeconds;
  final bool completed;
  const MediaHistoryEntity({
    required this.internalId,
    required this.mediaId,
    required this.accessedAt,
    this.progressSeconds,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['internal_id'] = Variable<int>(internalId);
    map['media_id'] = Variable<int>(mediaId);
    map['accessed_at'] = Variable<DateTime>(accessedAt);
    if (!nullToAbsent || progressSeconds != null) {
      map['progress_seconds'] = Variable<BigInt>(progressSeconds);
    }
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  MediaHistoryCompanion toCompanion(bool nullToAbsent) {
    return MediaHistoryCompanion(
      internalId: Value(internalId),
      mediaId: Value(mediaId),
      accessedAt: Value(accessedAt),
      progressSeconds: progressSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(progressSeconds),
      completed: Value(completed),
    );
  }

  factory MediaHistoryEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaHistoryEntity(
      internalId: serializer.fromJson<int>(json['internalId']),
      mediaId: serializer.fromJson<int>(json['mediaId']),
      accessedAt: serializer.fromJson<DateTime>(json['accessedAt']),
      progressSeconds: serializer.fromJson<BigInt?>(json['progressSeconds']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'internalId': serializer.toJson<int>(internalId),
      'mediaId': serializer.toJson<int>(mediaId),
      'accessedAt': serializer.toJson<DateTime>(accessedAt),
      'progressSeconds': serializer.toJson<BigInt?>(progressSeconds),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  MediaHistoryEntity copyWith({
    int? internalId,
    int? mediaId,
    DateTime? accessedAt,
    Value<BigInt?> progressSeconds = const Value.absent(),
    bool? completed,
  }) => MediaHistoryEntity(
    internalId: internalId ?? this.internalId,
    mediaId: mediaId ?? this.mediaId,
    accessedAt: accessedAt ?? this.accessedAt,
    progressSeconds: progressSeconds.present
        ? progressSeconds.value
        : this.progressSeconds,
    completed: completed ?? this.completed,
  );
  MediaHistoryEntity copyWithCompanion(MediaHistoryCompanion data) {
    return MediaHistoryEntity(
      internalId: data.internalId.present
          ? data.internalId.value
          : this.internalId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      accessedAt: data.accessedAt.present
          ? data.accessedAt.value
          : this.accessedAt,
      progressSeconds: data.progressSeconds.present
          ? data.progressSeconds.value
          : this.progressSeconds,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaHistoryEntity(')
          ..write('internalId: $internalId, ')
          ..write('mediaId: $mediaId, ')
          ..write('accessedAt: $accessedAt, ')
          ..write('progressSeconds: $progressSeconds, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(internalId, mediaId, accessedAt, progressSeconds, completed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaHistoryEntity &&
          other.internalId == this.internalId &&
          other.mediaId == this.mediaId &&
          other.accessedAt == this.accessedAt &&
          other.progressSeconds == this.progressSeconds &&
          other.completed == this.completed);
}

class MediaHistoryCompanion extends UpdateCompanion<MediaHistoryEntity> {
  final Value<int> internalId;
  final Value<int> mediaId;
  final Value<DateTime> accessedAt;
  final Value<BigInt?> progressSeconds;
  final Value<bool> completed;
  const MediaHistoryCompanion({
    this.internalId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.accessedAt = const Value.absent(),
    this.progressSeconds = const Value.absent(),
    this.completed = const Value.absent(),
  });
  MediaHistoryCompanion.insert({
    this.internalId = const Value.absent(),
    required int mediaId,
    this.accessedAt = const Value.absent(),
    this.progressSeconds = const Value.absent(),
    this.completed = const Value.absent(),
  }) : mediaId = Value(mediaId);
  static Insertable<MediaHistoryEntity> custom({
    Expression<int>? internalId,
    Expression<int>? mediaId,
    Expression<DateTime>? accessedAt,
    Expression<BigInt>? progressSeconds,
    Expression<bool>? completed,
  }) {
    return RawValuesInsertable({
      if (internalId != null) 'internal_id': internalId,
      if (mediaId != null) 'media_id': mediaId,
      if (accessedAt != null) 'accessed_at': accessedAt,
      if (progressSeconds != null) 'progress_seconds': progressSeconds,
      if (completed != null) 'completed': completed,
    });
  }

  MediaHistoryCompanion copyWith({
    Value<int>? internalId,
    Value<int>? mediaId,
    Value<DateTime>? accessedAt,
    Value<BigInt?>? progressSeconds,
    Value<bool>? completed,
  }) {
    return MediaHistoryCompanion(
      internalId: internalId ?? this.internalId,
      mediaId: mediaId ?? this.mediaId,
      accessedAt: accessedAt ?? this.accessedAt,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      completed: completed ?? this.completed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (internalId.present) {
      map['internal_id'] = Variable<int>(internalId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (accessedAt.present) {
      map['accessed_at'] = Variable<DateTime>(accessedAt.value);
    }
    if (progressSeconds.present) {
      map['progress_seconds'] = Variable<BigInt>(progressSeconds.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaHistoryCompanion(')
          ..write('internalId: $internalId, ')
          ..write('mediaId: $mediaId, ')
          ..write('accessedAt: $accessedAt, ')
          ..write('progressSeconds: $progressSeconds, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

class $VideoTable extends Video with TableInfo<$VideoTable, VideoEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media (internal_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<BigInt> duration = GeneratedColumn<BigInt>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewCountMeta = const VerificationMeta(
    'viewCount',
  );
  @override
  late final GeneratedColumn<BigInt> viewCount = GeneratedColumn<BigInt>(
    'view_count',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [mediaId, duration, viewCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video';
  @override
  VerificationContext validateIntegrity(
    Insertable<VideoEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('view_count')) {
      context.handle(
        _viewCountMeta,
        viewCount.isAcceptableOrUnknown(data['view_count']!, _viewCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  VideoEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoEntity(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}duration'],
      )!,
      viewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}view_count'],
      ),
    );
  }

  @override
  $VideoTable createAlias(String alias) {
    return $VideoTable(attachedDatabase, alias);
  }
}

class VideoEntity extends DataClass implements Insertable<VideoEntity> {
  final int mediaId;
  final BigInt duration;
  final BigInt? viewCount;
  const VideoEntity({
    required this.mediaId,
    required this.duration,
    this.viewCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<int>(mediaId);
    map['duration'] = Variable<BigInt>(duration);
    if (!nullToAbsent || viewCount != null) {
      map['view_count'] = Variable<BigInt>(viewCount);
    }
    return map;
  }

  VideoCompanion toCompanion(bool nullToAbsent) {
    return VideoCompanion(
      mediaId: Value(mediaId),
      duration: Value(duration),
      viewCount: viewCount == null && nullToAbsent
          ? const Value.absent()
          : Value(viewCount),
    );
  }

  factory VideoEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoEntity(
      mediaId: serializer.fromJson<int>(json['mediaId']),
      duration: serializer.fromJson<BigInt>(json['duration']),
      viewCount: serializer.fromJson<BigInt?>(json['viewCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<int>(mediaId),
      'duration': serializer.toJson<BigInt>(duration),
      'viewCount': serializer.toJson<BigInt?>(viewCount),
    };
  }

  VideoEntity copyWith({
    int? mediaId,
    BigInt? duration,
    Value<BigInt?> viewCount = const Value.absent(),
  }) => VideoEntity(
    mediaId: mediaId ?? this.mediaId,
    duration: duration ?? this.duration,
    viewCount: viewCount.present ? viewCount.value : this.viewCount,
  );
  VideoEntity copyWithCompanion(VideoCompanion data) {
    return VideoEntity(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      duration: data.duration.present ? data.duration.value : this.duration,
      viewCount: data.viewCount.present ? data.viewCount.value : this.viewCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoEntity(')
          ..write('mediaId: $mediaId, ')
          ..write('duration: $duration, ')
          ..write('viewCount: $viewCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, duration, viewCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoEntity &&
          other.mediaId == this.mediaId &&
          other.duration == this.duration &&
          other.viewCount == this.viewCount);
}

class VideoCompanion extends UpdateCompanion<VideoEntity> {
  final Value<int> mediaId;
  final Value<BigInt> duration;
  final Value<BigInt?> viewCount;
  const VideoCompanion({
    this.mediaId = const Value.absent(),
    this.duration = const Value.absent(),
    this.viewCount = const Value.absent(),
  });
  VideoCompanion.insert({
    this.mediaId = const Value.absent(),
    required BigInt duration,
    this.viewCount = const Value.absent(),
  }) : duration = Value(duration);
  static Insertable<VideoEntity> custom({
    Expression<int>? mediaId,
    Expression<BigInt>? duration,
    Expression<BigInt>? viewCount,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (duration != null) 'duration': duration,
      if (viewCount != null) 'view_count': viewCount,
    });
  }

  VideoCompanion copyWith({
    Value<int>? mediaId,
    Value<BigInt>? duration,
    Value<BigInt?>? viewCount,
  }) {
    return VideoCompanion(
      mediaId: mediaId ?? this.mediaId,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (duration.present) {
      map['duration'] = Variable<BigInt>(duration.value);
    }
    if (viewCount.present) {
      map['view_count'] = Variable<BigInt>(viewCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('duration: $duration, ')
          ..write('viewCount: $viewCount')
          ..write(')'))
        .toString();
  }
}

class $CreatorProfileTable extends CreatorProfile
    with TableInfo<$CreatorProfileTable, CreatorProfileEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreatorProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _internalIdMeta = const VerificationMeta(
    'internalId',
  );
  @override
  late final GeneratedColumn<int> internalId = GeneratedColumn<int>(
    'internal_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    internalId,
    serviceId,
    id,
    url,
    name,
    thumbnailUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'creator_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreatorProfileEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('internal_id')) {
      context.handle(
        _internalIdMeta,
        internalId.isAcceptableOrUnknown(data['internal_id']!, _internalIdMeta),
      );
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {internalId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {serviceId, id},
  ];
  @override
  CreatorProfileEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreatorProfileEntity(
      internalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}internal_id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
    );
  }

  @override
  $CreatorProfileTable createAlias(String alias) {
    return $CreatorProfileTable(attachedDatabase, alias);
  }
}

class CreatorProfileEntity extends DataClass
    implements Insertable<CreatorProfileEntity> {
  final int internalId;
  final String serviceId;
  final String id;
  final String url;
  final String name;
  final String? thumbnailUrl;
  const CreatorProfileEntity({
    required this.internalId,
    required this.serviceId,
    required this.id,
    required this.url,
    required this.name,
    this.thumbnailUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['internal_id'] = Variable<int>(internalId);
    map['service_id'] = Variable<String>(serviceId);
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    return map;
  }

  CreatorProfileCompanion toCompanion(bool nullToAbsent) {
    return CreatorProfileCompanion(
      internalId: Value(internalId),
      serviceId: Value(serviceId),
      id: Value(id),
      url: Value(url),
      name: Value(name),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
    );
  }

  factory CreatorProfileEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreatorProfileEntity(
      internalId: serializer.fromJson<int>(json['internalId']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      name: serializer.fromJson<String>(json['name']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'internalId': serializer.toJson<int>(internalId),
      'serviceId': serializer.toJson<String>(serviceId),
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'name': serializer.toJson<String>(name),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
    };
  }

  CreatorProfileEntity copyWith({
    int? internalId,
    String? serviceId,
    String? id,
    String? url,
    String? name,
    Value<String?> thumbnailUrl = const Value.absent(),
  }) => CreatorProfileEntity(
    internalId: internalId ?? this.internalId,
    serviceId: serviceId ?? this.serviceId,
    id: id ?? this.id,
    url: url ?? this.url,
    name: name ?? this.name,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
  );
  CreatorProfileEntity copyWithCompanion(CreatorProfileCompanion data) {
    return CreatorProfileEntity(
      internalId: data.internalId.present
          ? data.internalId.value
          : this.internalId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      name: data.name.present ? data.name.value : this.name,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreatorProfileEntity(')
          ..write('internalId: $internalId, ')
          ..write('serviceId: $serviceId, ')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('thumbnailUrl: $thumbnailUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(internalId, serviceId, id, url, name, thumbnailUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreatorProfileEntity &&
          other.internalId == this.internalId &&
          other.serviceId == this.serviceId &&
          other.id == this.id &&
          other.url == this.url &&
          other.name == this.name &&
          other.thumbnailUrl == this.thumbnailUrl);
}

class CreatorProfileCompanion extends UpdateCompanion<CreatorProfileEntity> {
  final Value<int> internalId;
  final Value<String> serviceId;
  final Value<String> id;
  final Value<String> url;
  final Value<String> name;
  final Value<String?> thumbnailUrl;
  const CreatorProfileCompanion({
    this.internalId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.name = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
  });
  CreatorProfileCompanion.insert({
    this.internalId = const Value.absent(),
    required String serviceId,
    required String id,
    required String url,
    required String name,
    this.thumbnailUrl = const Value.absent(),
  }) : serviceId = Value(serviceId),
       id = Value(id),
       url = Value(url),
       name = Value(name);
  static Insertable<CreatorProfileEntity> custom({
    Expression<int>? internalId,
    Expression<String>? serviceId,
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? name,
    Expression<String>? thumbnailUrl,
  }) {
    return RawValuesInsertable({
      if (internalId != null) 'internal_id': internalId,
      if (serviceId != null) 'service_id': serviceId,
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    });
  }

  CreatorProfileCompanion copyWith({
    Value<int>? internalId,
    Value<String>? serviceId,
    Value<String>? id,
    Value<String>? url,
    Value<String>? name,
    Value<String?>? thumbnailUrl,
  }) {
    return CreatorProfileCompanion(
      internalId: internalId ?? this.internalId,
      serviceId: serviceId ?? this.serviceId,
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (internalId.present) {
      map['internal_id'] = Variable<int>(internalId.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreatorProfileCompanion(')
          ..write('internalId: $internalId, ')
          ..write('serviceId: $serviceId, ')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('thumbnailUrl: $thumbnailUrl')
          ..write(')'))
        .toString();
  }
}

class $ArticleTable extends Article
    with TableInfo<$ArticleTable, ArticleEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media (internal_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<BigInt> wordCount = GeneratedColumn<BigInt>(
    'word_count',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [mediaId, content, author, wordCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  ArticleEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleEntity(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}word_count'],
      ),
    );
  }

  @override
  $ArticleTable createAlias(String alias) {
    return $ArticleTable(attachedDatabase, alias);
  }
}

class ArticleEntity extends DataClass implements Insertable<ArticleEntity> {
  final int mediaId;
  final String content;
  final String? author;
  final BigInt? wordCount;
  const ArticleEntity({
    required this.mediaId,
    required this.content,
    this.author,
    this.wordCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<int>(mediaId);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || wordCount != null) {
      map['word_count'] = Variable<BigInt>(wordCount);
    }
    return map;
  }

  ArticleCompanion toCompanion(bool nullToAbsent) {
    return ArticleCompanion(
      mediaId: Value(mediaId),
      content: Value(content),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      wordCount: wordCount == null && nullToAbsent
          ? const Value.absent()
          : Value(wordCount),
    );
  }

  factory ArticleEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleEntity(
      mediaId: serializer.fromJson<int>(json['mediaId']),
      content: serializer.fromJson<String>(json['content']),
      author: serializer.fromJson<String?>(json['author']),
      wordCount: serializer.fromJson<BigInt?>(json['wordCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<int>(mediaId),
      'content': serializer.toJson<String>(content),
      'author': serializer.toJson<String?>(author),
      'wordCount': serializer.toJson<BigInt?>(wordCount),
    };
  }

  ArticleEntity copyWith({
    int? mediaId,
    String? content,
    Value<String?> author = const Value.absent(),
    Value<BigInt?> wordCount = const Value.absent(),
  }) => ArticleEntity(
    mediaId: mediaId ?? this.mediaId,
    content: content ?? this.content,
    author: author.present ? author.value : this.author,
    wordCount: wordCount.present ? wordCount.value : this.wordCount,
  );
  ArticleEntity copyWithCompanion(ArticleCompanion data) {
    return ArticleEntity(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      content: data.content.present ? data.content.value : this.content,
      author: data.author.present ? data.author.value : this.author,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleEntity(')
          ..write('mediaId: $mediaId, ')
          ..write('content: $content, ')
          ..write('author: $author, ')
          ..write('wordCount: $wordCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, content, author, wordCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleEntity &&
          other.mediaId == this.mediaId &&
          other.content == this.content &&
          other.author == this.author &&
          other.wordCount == this.wordCount);
}

class ArticleCompanion extends UpdateCompanion<ArticleEntity> {
  final Value<int> mediaId;
  final Value<String> content;
  final Value<String?> author;
  final Value<BigInt?> wordCount;
  const ArticleCompanion({
    this.mediaId = const Value.absent(),
    this.content = const Value.absent(),
    this.author = const Value.absent(),
    this.wordCount = const Value.absent(),
  });
  ArticleCompanion.insert({
    this.mediaId = const Value.absent(),
    required String content,
    this.author = const Value.absent(),
    this.wordCount = const Value.absent(),
  }) : content = Value(content);
  static Insertable<ArticleEntity> custom({
    Expression<int>? mediaId,
    Expression<String>? content,
    Expression<String>? author,
    Expression<BigInt>? wordCount,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (content != null) 'content': content,
      if (author != null) 'author': author,
      if (wordCount != null) 'word_count': wordCount,
    });
  }

  ArticleCompanion copyWith({
    Value<int>? mediaId,
    Value<String>? content,
    Value<String?>? author,
    Value<BigInt?>? wordCount,
  }) {
    return ArticleCompanion(
      mediaId: mediaId ?? this.mediaId,
      content: content ?? this.content,
      author: author ?? this.author,
      wordCount: wordCount ?? this.wordCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<BigInt>(wordCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticleCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('content: $content, ')
          ..write('author: $author, ')
          ..write('wordCount: $wordCount')
          ..write(')'))
        .toString();
  }
}

class $PostTable extends Post with TableInfo<$PostTable, PostEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media (internal_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlsJsonMeta = const VerificationMeta(
    'imageUrlsJson',
  );
  @override
  late final GeneratedColumn<String> imageUrlsJson = GeneratedColumn<String>(
    'image_urls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [mediaId, content, imageUrlsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'post';
  @override
  VerificationContext validateIntegrity(
    Insertable<PostEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('image_urls_json')) {
      context.handle(
        _imageUrlsJsonMeta,
        imageUrlsJson.isAcceptableOrUnknown(
          data['image_urls_json']!,
          _imageUrlsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_imageUrlsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  PostEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PostEntity(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      imageUrlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_urls_json'],
      )!,
    );
  }

  @override
  $PostTable createAlias(String alias) {
    return $PostTable(attachedDatabase, alias);
  }
}

class PostEntity extends DataClass implements Insertable<PostEntity> {
  final int mediaId;
  final String content;
  final String imageUrlsJson;
  const PostEntity({
    required this.mediaId,
    required this.content,
    required this.imageUrlsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<int>(mediaId);
    map['content'] = Variable<String>(content);
    map['image_urls_json'] = Variable<String>(imageUrlsJson);
    return map;
  }

  PostCompanion toCompanion(bool nullToAbsent) {
    return PostCompanion(
      mediaId: Value(mediaId),
      content: Value(content),
      imageUrlsJson: Value(imageUrlsJson),
    );
  }

  factory PostEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PostEntity(
      mediaId: serializer.fromJson<int>(json['mediaId']),
      content: serializer.fromJson<String>(json['content']),
      imageUrlsJson: serializer.fromJson<String>(json['imageUrlsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<int>(mediaId),
      'content': serializer.toJson<String>(content),
      'imageUrlsJson': serializer.toJson<String>(imageUrlsJson),
    };
  }

  PostEntity copyWith({int? mediaId, String? content, String? imageUrlsJson}) =>
      PostEntity(
        mediaId: mediaId ?? this.mediaId,
        content: content ?? this.content,
        imageUrlsJson: imageUrlsJson ?? this.imageUrlsJson,
      );
  PostEntity copyWithCompanion(PostCompanion data) {
    return PostEntity(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      content: data.content.present ? data.content.value : this.content,
      imageUrlsJson: data.imageUrlsJson.present
          ? data.imageUrlsJson.value
          : this.imageUrlsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PostEntity(')
          ..write('mediaId: $mediaId, ')
          ..write('content: $content, ')
          ..write('imageUrlsJson: $imageUrlsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, content, imageUrlsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostEntity &&
          other.mediaId == this.mediaId &&
          other.content == this.content &&
          other.imageUrlsJson == this.imageUrlsJson);
}

class PostCompanion extends UpdateCompanion<PostEntity> {
  final Value<int> mediaId;
  final Value<String> content;
  final Value<String> imageUrlsJson;
  const PostCompanion({
    this.mediaId = const Value.absent(),
    this.content = const Value.absent(),
    this.imageUrlsJson = const Value.absent(),
  });
  PostCompanion.insert({
    this.mediaId = const Value.absent(),
    required String content,
    required String imageUrlsJson,
  }) : content = Value(content),
       imageUrlsJson = Value(imageUrlsJson);
  static Insertable<PostEntity> custom({
    Expression<int>? mediaId,
    Expression<String>? content,
    Expression<String>? imageUrlsJson,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (content != null) 'content': content,
      if (imageUrlsJson != null) 'image_urls_json': imageUrlsJson,
    });
  }

  PostCompanion copyWith({
    Value<int>? mediaId,
    Value<String>? content,
    Value<String>? imageUrlsJson,
  }) {
    return PostCompanion(
      mediaId: mediaId ?? this.mediaId,
      content: content ?? this.content,
      imageUrlsJson: imageUrlsJson ?? this.imageUrlsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (imageUrlsJson.present) {
      map['image_urls_json'] = Variable<String>(imageUrlsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('content: $content, ')
          ..write('imageUrlsJson: $imageUrlsJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecentSearchQueryTable recentSearchQuery =
      $RecentSearchQueryTable(this);
  late final $MediaTable media = $MediaTable(this);
  late final $MediaHistoryTable mediaHistory = $MediaHistoryTable(this);
  late final $VideoTable video = $VideoTable(this);
  late final $CreatorProfileTable creatorProfile = $CreatorProfileTable(this);
  late final $ArticleTable article = $ArticleTable(this);
  late final $PostTable post = $PostTable(this);
  late final RecentSearchQueryDao recentSearchQueryDao = RecentSearchQueryDao(
    this as AppDatabase,
  );
  late final MediaHistoryDao mediaHistoryDao = MediaHistoryDao(
    this as AppDatabase,
  );
  late final VideoDao videoDao = VideoDao(this as AppDatabase);
  late final CreatorProfileDao creatorProfileDao = CreatorProfileDao(
    this as AppDatabase,
  );
  late final ArticleDao articleDao = ArticleDao(this as AppDatabase);
  late final PostDao postDao = PostDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recentSearchQuery,
    media,
    mediaHistory,
    video,
    creatorProfile,
    article,
    post,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('video', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('article', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('post', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$RecentSearchQueryTableCreateCompanionBuilder =
    RecentSearchQueryCompanion Function({
      required String query,
      Value<DateTime> queriedDate,
      Value<int> rowid,
    });
typedef $$RecentSearchQueryTableUpdateCompanionBuilder =
    RecentSearchQueryCompanion Function({
      Value<String> query,
      Value<DateTime> queriedDate,
      Value<int> rowid,
    });

class $$RecentSearchQueryTableFilterComposer
    extends Composer<_$AppDatabase, $RecentSearchQueryTable> {
  $$RecentSearchQueryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queriedDate => $composableBuilder(
    column: $table.queriedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentSearchQueryTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentSearchQueryTable> {
  $$RecentSearchQueryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queriedDate => $composableBuilder(
    column: $table.queriedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentSearchQueryTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentSearchQueryTable> {
  $$RecentSearchQueryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get queriedDate => $composableBuilder(
    column: $table.queriedDate,
    builder: (column) => column,
  );
}

class $$RecentSearchQueryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentSearchQueryTable,
          RecentSearchQueryEntity,
          $$RecentSearchQueryTableFilterComposer,
          $$RecentSearchQueryTableOrderingComposer,
          $$RecentSearchQueryTableAnnotationComposer,
          $$RecentSearchQueryTableCreateCompanionBuilder,
          $$RecentSearchQueryTableUpdateCompanionBuilder,
          (
            RecentSearchQueryEntity,
            BaseReferences<
              _$AppDatabase,
              $RecentSearchQueryTable,
              RecentSearchQueryEntity
            >,
          ),
          RecentSearchQueryEntity,
          PrefetchHooks Function()
        > {
  $$RecentSearchQueryTableTableManager(
    _$AppDatabase db,
    $RecentSearchQueryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentSearchQueryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentSearchQueryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentSearchQueryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<DateTime> queriedDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentSearchQueryCompanion(
                query: query,
                queriedDate: queriedDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                Value<DateTime> queriedDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentSearchQueryCompanion.insert(
                query: query,
                queriedDate: queriedDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentSearchQueryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentSearchQueryTable,
      RecentSearchQueryEntity,
      $$RecentSearchQueryTableFilterComposer,
      $$RecentSearchQueryTableOrderingComposer,
      $$RecentSearchQueryTableAnnotationComposer,
      $$RecentSearchQueryTableCreateCompanionBuilder,
      $$RecentSearchQueryTableUpdateCompanionBuilder,
      (
        RecentSearchQueryEntity,
        BaseReferences<
          _$AppDatabase,
          $RecentSearchQueryTable,
          RecentSearchQueryEntity
        >,
      ),
      RecentSearchQueryEntity,
      PrefetchHooks Function()
    >;
typedef $$MediaTableCreateCompanionBuilder =
    MediaCompanion Function({
      Value<int> internalId,
      required String sourceId,
      required String originalId,
      required String title,
      required String url,
      Value<String?> thumbnailUrl,
      Value<String?> creatorProfileName,
      Value<String?> creatorProfileId,
      Value<DateTime?> uploadDate,
      required String type,
    });
typedef $$MediaTableUpdateCompanionBuilder =
    MediaCompanion Function({
      Value<int> internalId,
      Value<String> sourceId,
      Value<String> originalId,
      Value<String> title,
      Value<String> url,
      Value<String?> thumbnailUrl,
      Value<String?> creatorProfileName,
      Value<String?> creatorProfileId,
      Value<DateTime?> uploadDate,
      Value<String> type,
    });

final class $$MediaTableReferences
    extends BaseReferences<_$AppDatabase, $MediaTable, MediaEntity> {
  $$MediaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaHistoryTable, List<MediaHistoryEntity>>
  _mediaHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaHistory,
    aliasName: 'media__internal_id__media_history__media_id',
  );

  $$MediaHistoryTableProcessedTableManager get mediaHistoryRefs {
    final manager = $$MediaHistoryTableTableManager($_db, $_db.mediaHistory)
        .filter(
          (f) =>
              f.mediaId.internalId.sqlEquals($_itemColumn<int>('internal_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_mediaHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VideoTable, List<VideoEntity>> _videoRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.video,
    aliasName: 'media__internal_id__video__media_id',
  );

  $$VideoTableProcessedTableManager get videoRefs {
    final manager = $$VideoTableTableManager($_db, $_db.video).filter(
      (f) => f.mediaId.internalId.sqlEquals($_itemColumn<int>('internal_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_videoRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArticleTable, List<ArticleEntity>>
  _articleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.article,
    aliasName: 'media__internal_id__article__media_id',
  );

  $$ArticleTableProcessedTableManager get articleRefs {
    final manager = $$ArticleTableTableManager($_db, $_db.article).filter(
      (f) => f.mediaId.internalId.sqlEquals($_itemColumn<int>('internal_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_articleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PostTable, List<PostEntity>> _postRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.post,
    aliasName: 'media__internal_id__post__media_id',
  );

  $$PostTableProcessedTableManager get postRefs {
    final manager = $$PostTableTableManager($_db, $_db.post).filter(
      (f) => f.mediaId.internalId.sqlEquals($_itemColumn<int>('internal_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_postRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaTableFilterComposer extends Composer<_$AppDatabase, $MediaTable> {
  $$MediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalId => $composableBuilder(
    column: $table.originalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorProfileName => $composableBuilder(
    column: $table.creatorProfileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorProfileId => $composableBuilder(
    column: $table.creatorProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get uploadDate => $composableBuilder(
    column: $table.uploadDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaHistoryRefs(
    Expression<bool> Function($$MediaHistoryTableFilterComposer f) f,
  ) {
    final $$MediaHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.mediaHistory,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaHistoryTableFilterComposer(
            $db: $db,
            $table: $db.mediaHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> videoRefs(
    Expression<bool> Function($$VideoTableFilterComposer f) f,
  ) {
    final $$VideoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.video,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideoTableFilterComposer(
            $db: $db,
            $table: $db.video,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> articleRefs(
    Expression<bool> Function($$ArticleTableFilterComposer f) f,
  ) {
    final $$ArticleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.article,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticleTableFilterComposer(
            $db: $db,
            $table: $db.article,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> postRefs(
    Expression<bool> Function($$PostTableFilterComposer f) f,
  ) {
    final $$PostTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.post,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PostTableFilterComposer(
            $db: $db,
            $table: $db.post,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaTable> {
  $$MediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalId => $composableBuilder(
    column: $table.originalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorProfileName => $composableBuilder(
    column: $table.creatorProfileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorProfileId => $composableBuilder(
    column: $table.creatorProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get uploadDate => $composableBuilder(
    column: $table.uploadDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaTable> {
  $$MediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get originalId => $composableBuilder(
    column: $table.originalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creatorProfileName => $composableBuilder(
    column: $table.creatorProfileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creatorProfileId => $composableBuilder(
    column: $table.creatorProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get uploadDate => $composableBuilder(
    column: $table.uploadDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  Expression<T> mediaHistoryRefs<T extends Object>(
    Expression<T> Function($$MediaHistoryTableAnnotationComposer a) f,
  ) {
    final $$MediaHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.mediaHistory,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> videoRefs<T extends Object>(
    Expression<T> Function($$VideoTableAnnotationComposer a) f,
  ) {
    final $$VideoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.video,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideoTableAnnotationComposer(
            $db: $db,
            $table: $db.video,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> articleRefs<T extends Object>(
    Expression<T> Function($$ArticleTableAnnotationComposer a) f,
  ) {
    final $$ArticleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.article,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticleTableAnnotationComposer(
            $db: $db,
            $table: $db.article,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> postRefs<T extends Object>(
    Expression<T> Function($$PostTableAnnotationComposer a) f,
  ) {
    final $$PostTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.internalId,
      referencedTable: $db.post,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PostTableAnnotationComposer(
            $db: $db,
            $table: $db.post,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaTable,
          MediaEntity,
          $$MediaTableFilterComposer,
          $$MediaTableOrderingComposer,
          $$MediaTableAnnotationComposer,
          $$MediaTableCreateCompanionBuilder,
          $$MediaTableUpdateCompanionBuilder,
          (MediaEntity, $$MediaTableReferences),
          MediaEntity,
          PrefetchHooks Function({
            bool mediaHistoryRefs,
            bool videoRefs,
            bool articleRefs,
            bool postRefs,
          })
        > {
  $$MediaTableTableManager(_$AppDatabase db, $MediaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> internalId = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> originalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> creatorProfileName = const Value.absent(),
                Value<String?> creatorProfileId = const Value.absent(),
                Value<DateTime?> uploadDate = const Value.absent(),
                Value<String> type = const Value.absent(),
              }) => MediaCompanion(
                internalId: internalId,
                sourceId: sourceId,
                originalId: originalId,
                title: title,
                url: url,
                thumbnailUrl: thumbnailUrl,
                creatorProfileName: creatorProfileName,
                creatorProfileId: creatorProfileId,
                uploadDate: uploadDate,
                type: type,
              ),
          createCompanionCallback:
              ({
                Value<int> internalId = const Value.absent(),
                required String sourceId,
                required String originalId,
                required String title,
                required String url,
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> creatorProfileName = const Value.absent(),
                Value<String?> creatorProfileId = const Value.absent(),
                Value<DateTime?> uploadDate = const Value.absent(),
                required String type,
              }) => MediaCompanion.insert(
                internalId: internalId,
                sourceId: sourceId,
                originalId: originalId,
                title: title,
                url: url,
                thumbnailUrl: thumbnailUrl,
                creatorProfileName: creatorProfileName,
                creatorProfileId: creatorProfileId,
                uploadDate: uploadDate,
                type: type,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MediaTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                mediaHistoryRefs = false,
                videoRefs = false,
                articleRefs = false,
                postRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaHistoryRefs) db.mediaHistory,
                    if (videoRefs) db.video,
                    if (articleRefs) db.article,
                    if (postRefs) db.post,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaHistoryRefs)
                        await $_getPrefetchedData<
                          MediaEntity,
                          $MediaTable,
                          MediaHistoryEntity
                        >(
                          currentTable: table,
                          referencedTable: $$MediaTableReferences
                              ._mediaHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.internalId,
                              ),
                          typedResults: items,
                        ),
                      if (videoRefs)
                        await $_getPrefetchedData<
                          MediaEntity,
                          $MediaTable,
                          VideoEntity
                        >(
                          currentTable: table,
                          referencedTable: $$MediaTableReferences
                              ._videoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaTableReferences(db, table, p0).videoRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.internalId,
                              ),
                          typedResults: items,
                        ),
                      if (articleRefs)
                        await $_getPrefetchedData<
                          MediaEntity,
                          $MediaTable,
                          ArticleEntity
                        >(
                          currentTable: table,
                          referencedTable: $$MediaTableReferences
                              ._articleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaTableReferences(db, table, p0).articleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.internalId,
                              ),
                          typedResults: items,
                        ),
                      if (postRefs)
                        await $_getPrefetchedData<
                          MediaEntity,
                          $MediaTable,
                          PostEntity
                        >(
                          currentTable: table,
                          referencedTable: $$MediaTableReferences
                              ._postRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaTableReferences(db, table, p0).postRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.internalId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaTable,
      MediaEntity,
      $$MediaTableFilterComposer,
      $$MediaTableOrderingComposer,
      $$MediaTableAnnotationComposer,
      $$MediaTableCreateCompanionBuilder,
      $$MediaTableUpdateCompanionBuilder,
      (MediaEntity, $$MediaTableReferences),
      MediaEntity,
      PrefetchHooks Function({
        bool mediaHistoryRefs,
        bool videoRefs,
        bool articleRefs,
        bool postRefs,
      })
    >;
typedef $$MediaHistoryTableCreateCompanionBuilder =
    MediaHistoryCompanion Function({
      Value<int> internalId,
      required int mediaId,
      Value<DateTime> accessedAt,
      Value<BigInt?> progressSeconds,
      Value<bool> completed,
    });
typedef $$MediaHistoryTableUpdateCompanionBuilder =
    MediaHistoryCompanion Function({
      Value<int> internalId,
      Value<int> mediaId,
      Value<DateTime> accessedAt,
      Value<BigInt?> progressSeconds,
      Value<bool> completed,
    });

final class $$MediaHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $MediaHistoryTable, MediaHistoryEntity> {
  $$MediaHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaTable _mediaIdTable(_$AppDatabase db) =>
      db.media.createAlias('media_history__media_id__media__internal_id');

  $$MediaTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<int>('media_id')!;

    final manager = $$MediaTableTableManager(
      $_db,
      $_db.media,
    ).filter((f) => f.internalId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $MediaHistoryTable> {
  $$MediaHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get accessedAt => $composableBuilder(
    column: $table.accessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get progressSeconds => $composableBuilder(
    column: $table.progressSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaTableFilterComposer get mediaId {
    final $$MediaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableFilterComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaHistoryTable> {
  $$MediaHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get accessedAt => $composableBuilder(
    column: $table.accessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get progressSeconds => $composableBuilder(
    column: $table.progressSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaTableOrderingComposer get mediaId {
    final $$MediaTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableOrderingComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaHistoryTable> {
  $$MediaHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get accessedAt => $composableBuilder(
    column: $table.accessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get progressSeconds => $composableBuilder(
    column: $table.progressSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  $$MediaTableAnnotationComposer get mediaId {
    final $$MediaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableAnnotationComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaHistoryTable,
          MediaHistoryEntity,
          $$MediaHistoryTableFilterComposer,
          $$MediaHistoryTableOrderingComposer,
          $$MediaHistoryTableAnnotationComposer,
          $$MediaHistoryTableCreateCompanionBuilder,
          $$MediaHistoryTableUpdateCompanionBuilder,
          (MediaHistoryEntity, $$MediaHistoryTableReferences),
          MediaHistoryEntity,
          PrefetchHooks Function({bool mediaId})
        > {
  $$MediaHistoryTableTableManager(_$AppDatabase db, $MediaHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> internalId = const Value.absent(),
                Value<int> mediaId = const Value.absent(),
                Value<DateTime> accessedAt = const Value.absent(),
                Value<BigInt?> progressSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => MediaHistoryCompanion(
                internalId: internalId,
                mediaId: mediaId,
                accessedAt: accessedAt,
                progressSeconds: progressSeconds,
                completed: completed,
              ),
          createCompanionCallback:
              ({
                Value<int> internalId = const Value.absent(),
                required int mediaId,
                Value<DateTime> accessedAt = const Value.absent(),
                Value<BigInt?> progressSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => MediaHistoryCompanion.insert(
                internalId: internalId,
                mediaId: mediaId,
                accessedAt: accessedAt,
                progressSeconds: progressSeconds,
                completed: completed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$MediaHistoryTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$MediaHistoryTableReferences
                                    ._mediaIdTable(db)
                                    .internalId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MediaHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaHistoryTable,
      MediaHistoryEntity,
      $$MediaHistoryTableFilterComposer,
      $$MediaHistoryTableOrderingComposer,
      $$MediaHistoryTableAnnotationComposer,
      $$MediaHistoryTableCreateCompanionBuilder,
      $$MediaHistoryTableUpdateCompanionBuilder,
      (MediaHistoryEntity, $$MediaHistoryTableReferences),
      MediaHistoryEntity,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$VideoTableCreateCompanionBuilder =
    VideoCompanion Function({
      Value<int> mediaId,
      required BigInt duration,
      Value<BigInt?> viewCount,
    });
typedef $$VideoTableUpdateCompanionBuilder =
    VideoCompanion Function({
      Value<int> mediaId,
      Value<BigInt> duration,
      Value<BigInt?> viewCount,
    });

final class $$VideoTableReferences
    extends BaseReferences<_$AppDatabase, $VideoTable, VideoEntity> {
  $$VideoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaTable _mediaIdTable(_$AppDatabase db) =>
      db.media.createAlias('video__media_id__media__internal_id');

  $$MediaTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<int>('media_id')!;

    final manager = $$MediaTableTableManager(
      $_db,
      $_db.media,
    ).filter((f) => f.internalId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VideoTableFilterComposer extends Composer<_$AppDatabase, $VideoTable> {
  $$VideoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<BigInt> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get viewCount => $composableBuilder(
    column: $table.viewCount,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaTableFilterComposer get mediaId {
    final $$MediaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableFilterComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VideoTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoTable> {
  $$VideoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<BigInt> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get viewCount => $composableBuilder(
    column: $table.viewCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaTableOrderingComposer get mediaId {
    final $$MediaTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableOrderingComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VideoTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoTable> {
  $$VideoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<BigInt> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<BigInt> get viewCount =>
      $composableBuilder(column: $table.viewCount, builder: (column) => column);

  $$MediaTableAnnotationComposer get mediaId {
    final $$MediaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableAnnotationComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VideoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideoTable,
          VideoEntity,
          $$VideoTableFilterComposer,
          $$VideoTableOrderingComposer,
          $$VideoTableAnnotationComposer,
          $$VideoTableCreateCompanionBuilder,
          $$VideoTableUpdateCompanionBuilder,
          (VideoEntity, $$VideoTableReferences),
          VideoEntity,
          PrefetchHooks Function({bool mediaId})
        > {
  $$VideoTableTableManager(_$AppDatabase db, $VideoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                Value<BigInt> duration = const Value.absent(),
                Value<BigInt?> viewCount = const Value.absent(),
              }) => VideoCompanion(
                mediaId: mediaId,
                duration: duration,
                viewCount: viewCount,
              ),
          createCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                required BigInt duration,
                Value<BigInt?> viewCount = const Value.absent(),
              }) => VideoCompanion.insert(
                mediaId: mediaId,
                duration: duration,
                viewCount: viewCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$VideoTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$VideoTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$VideoTableReferences
                                    ._mediaIdTable(db)
                                    .internalId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VideoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideoTable,
      VideoEntity,
      $$VideoTableFilterComposer,
      $$VideoTableOrderingComposer,
      $$VideoTableAnnotationComposer,
      $$VideoTableCreateCompanionBuilder,
      $$VideoTableUpdateCompanionBuilder,
      (VideoEntity, $$VideoTableReferences),
      VideoEntity,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$CreatorProfileTableCreateCompanionBuilder =
    CreatorProfileCompanion Function({
      Value<int> internalId,
      required String serviceId,
      required String id,
      required String url,
      required String name,
      Value<String?> thumbnailUrl,
    });
typedef $$CreatorProfileTableUpdateCompanionBuilder =
    CreatorProfileCompanion Function({
      Value<int> internalId,
      Value<String> serviceId,
      Value<String> id,
      Value<String> url,
      Value<String> name,
      Value<String?> thumbnailUrl,
    });

class $$CreatorProfileTableFilterComposer
    extends Composer<_$AppDatabase, $CreatorProfileTable> {
  $$CreatorProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CreatorProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $CreatorProfileTable> {
  $$CreatorProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreatorProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreatorProfileTable> {
  $$CreatorProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get internalId => $composableBuilder(
    column: $table.internalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );
}

class $$CreatorProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreatorProfileTable,
          CreatorProfileEntity,
          $$CreatorProfileTableFilterComposer,
          $$CreatorProfileTableOrderingComposer,
          $$CreatorProfileTableAnnotationComposer,
          $$CreatorProfileTableCreateCompanionBuilder,
          $$CreatorProfileTableUpdateCompanionBuilder,
          (
            CreatorProfileEntity,
            BaseReferences<
              _$AppDatabase,
              $CreatorProfileTable,
              CreatorProfileEntity
            >,
          ),
          CreatorProfileEntity,
          PrefetchHooks Function()
        > {
  $$CreatorProfileTableTableManager(
    _$AppDatabase db,
    $CreatorProfileTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreatorProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreatorProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreatorProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> internalId = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
              }) => CreatorProfileCompanion(
                internalId: internalId,
                serviceId: serviceId,
                id: id,
                url: url,
                name: name,
                thumbnailUrl: thumbnailUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> internalId = const Value.absent(),
                required String serviceId,
                required String id,
                required String url,
                required String name,
                Value<String?> thumbnailUrl = const Value.absent(),
              }) => CreatorProfileCompanion.insert(
                internalId: internalId,
                serviceId: serviceId,
                id: id,
                url: url,
                name: name,
                thumbnailUrl: thumbnailUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CreatorProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreatorProfileTable,
      CreatorProfileEntity,
      $$CreatorProfileTableFilterComposer,
      $$CreatorProfileTableOrderingComposer,
      $$CreatorProfileTableAnnotationComposer,
      $$CreatorProfileTableCreateCompanionBuilder,
      $$CreatorProfileTableUpdateCompanionBuilder,
      (
        CreatorProfileEntity,
        BaseReferences<
          _$AppDatabase,
          $CreatorProfileTable,
          CreatorProfileEntity
        >,
      ),
      CreatorProfileEntity,
      PrefetchHooks Function()
    >;
typedef $$ArticleTableCreateCompanionBuilder =
    ArticleCompanion Function({
      Value<int> mediaId,
      required String content,
      Value<String?> author,
      Value<BigInt?> wordCount,
    });
typedef $$ArticleTableUpdateCompanionBuilder =
    ArticleCompanion Function({
      Value<int> mediaId,
      Value<String> content,
      Value<String?> author,
      Value<BigInt?> wordCount,
    });

final class $$ArticleTableReferences
    extends BaseReferences<_$AppDatabase, $ArticleTable, ArticleEntity> {
  $$ArticleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaTable _mediaIdTable(_$AppDatabase db) =>
      db.media.createAlias('article__media_id__media__internal_id');

  $$MediaTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<int>('media_id')!;

    final manager = $$MediaTableTableManager(
      $_db,
      $_db.media,
    ).filter((f) => f.internalId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArticleTableFilterComposer
    extends Composer<_$AppDatabase, $ArticleTable> {
  $$ArticleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaTableFilterComposer get mediaId {
    final $$MediaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableFilterComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArticleTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticleTable> {
  $$ArticleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaTableOrderingComposer get mediaId {
    final $$MediaTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableOrderingComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArticleTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticleTable> {
  $$ArticleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<BigInt> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  $$MediaTableAnnotationComposer get mediaId {
    final $$MediaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableAnnotationComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArticleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticleTable,
          ArticleEntity,
          $$ArticleTableFilterComposer,
          $$ArticleTableOrderingComposer,
          $$ArticleTableAnnotationComposer,
          $$ArticleTableCreateCompanionBuilder,
          $$ArticleTableUpdateCompanionBuilder,
          (ArticleEntity, $$ArticleTableReferences),
          ArticleEntity,
          PrefetchHooks Function({bool mediaId})
        > {
  $$ArticleTableTableManager(_$AppDatabase db, $ArticleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<BigInt?> wordCount = const Value.absent(),
              }) => ArticleCompanion(
                mediaId: mediaId,
                content: content,
                author: author,
                wordCount: wordCount,
              ),
          createCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                required String content,
                Value<String?> author = const Value.absent(),
                Value<BigInt?> wordCount = const Value.absent(),
              }) => ArticleCompanion.insert(
                mediaId: mediaId,
                content: content,
                author: author,
                wordCount: wordCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ArticleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$ArticleTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$ArticleTableReferences
                                    ._mediaIdTable(db)
                                    .internalId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ArticleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticleTable,
      ArticleEntity,
      $$ArticleTableFilterComposer,
      $$ArticleTableOrderingComposer,
      $$ArticleTableAnnotationComposer,
      $$ArticleTableCreateCompanionBuilder,
      $$ArticleTableUpdateCompanionBuilder,
      (ArticleEntity, $$ArticleTableReferences),
      ArticleEntity,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$PostTableCreateCompanionBuilder =
    PostCompanion Function({
      Value<int> mediaId,
      required String content,
      required String imageUrlsJson,
    });
typedef $$PostTableUpdateCompanionBuilder =
    PostCompanion Function({
      Value<int> mediaId,
      Value<String> content,
      Value<String> imageUrlsJson,
    });

final class $$PostTableReferences
    extends BaseReferences<_$AppDatabase, $PostTable, PostEntity> {
  $$PostTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaTable _mediaIdTable(_$AppDatabase db) =>
      db.media.createAlias('post__media_id__media__internal_id');

  $$MediaTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<int>('media_id')!;

    final manager = $$MediaTableTableManager(
      $_db,
      $_db.media,
    ).filter((f) => f.internalId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PostTableFilterComposer extends Composer<_$AppDatabase, $PostTable> {
  $$PostTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaTableFilterComposer get mediaId {
    final $$MediaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableFilterComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostTableOrderingComposer extends Composer<_$AppDatabase, $PostTable> {
  $$PostTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaTableOrderingComposer get mediaId {
    final $$MediaTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableOrderingComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostTable> {
  $$PostTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => column,
  );

  $$MediaTableAnnotationComposer get mediaId {
    final $$MediaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.internalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableAnnotationComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostTable,
          PostEntity,
          $$PostTableFilterComposer,
          $$PostTableOrderingComposer,
          $$PostTableAnnotationComposer,
          $$PostTableCreateCompanionBuilder,
          $$PostTableUpdateCompanionBuilder,
          (PostEntity, $$PostTableReferences),
          PostEntity,
          PrefetchHooks Function({bool mediaId})
        > {
  $$PostTableTableManager(_$AppDatabase db, $PostTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> imageUrlsJson = const Value.absent(),
              }) => PostCompanion(
                mediaId: mediaId,
                content: content,
                imageUrlsJson: imageUrlsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                required String content,
                required String imageUrlsJson,
              }) => PostCompanion.insert(
                mediaId: mediaId,
                content: content,
                imageUrlsJson: imageUrlsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PostTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$PostTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$PostTableReferences
                                    ._mediaIdTable(db)
                                    .internalId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PostTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostTable,
      PostEntity,
      $$PostTableFilterComposer,
      $$PostTableOrderingComposer,
      $$PostTableAnnotationComposer,
      $$PostTableCreateCompanionBuilder,
      $$PostTableUpdateCompanionBuilder,
      (PostEntity, $$PostTableReferences),
      PostEntity,
      PrefetchHooks Function({bool mediaId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecentSearchQueryTableTableManager get recentSearchQuery =>
      $$RecentSearchQueryTableTableManager(_db, _db.recentSearchQuery);
  $$MediaTableTableManager get media =>
      $$MediaTableTableManager(_db, _db.media);
  $$MediaHistoryTableTableManager get mediaHistory =>
      $$MediaHistoryTableTableManager(_db, _db.mediaHistory);
  $$VideoTableTableManager get video =>
      $$VideoTableTableManager(_db, _db.video);
  $$CreatorProfileTableTableManager get creatorProfile =>
      $$CreatorProfileTableTableManager(_db, _db.creatorProfile);
  $$ArticleTableTableManager get article =>
      $$ArticleTableTableManager(_db, _db.article);
  $$PostTableTableManager get post => $$PostTableTableManager(_db, _db.post);
}
