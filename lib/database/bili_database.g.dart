// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bili_database.dart';

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

abstract class _$BiliDatabase extends GeneratedDatabase {
  _$BiliDatabase(QueryExecutor e) : super(e);
  $BiliDatabaseManager get managers => $BiliDatabaseManager(this);
  late final $RecentSearchQueryTable recentSearchQuery =
      $RecentSearchQueryTable(this);
  late final RecentSearchQueryDao recentSearchQueryDao = RecentSearchQueryDao(
    this as BiliDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [recentSearchQuery];
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
    extends Composer<_$BiliDatabase, $RecentSearchQueryTable> {
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
    extends Composer<_$BiliDatabase, $RecentSearchQueryTable> {
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
    extends Composer<_$BiliDatabase, $RecentSearchQueryTable> {
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
          _$BiliDatabase,
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
              _$BiliDatabase,
              $RecentSearchQueryTable,
              RecentSearchQueryEntity
            >,
          ),
          RecentSearchQueryEntity,
          PrefetchHooks Function()
        > {
  $$RecentSearchQueryTableTableManager(
    _$BiliDatabase db,
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
      _$BiliDatabase,
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
          _$BiliDatabase,
          $RecentSearchQueryTable,
          RecentSearchQueryEntity
        >,
      ),
      RecentSearchQueryEntity,
      PrefetchHooks Function()
    >;

class $BiliDatabaseManager {
  final _$BiliDatabase _db;
  $BiliDatabaseManager(this._db);
  $$RecentSearchQueryTableTableManager get recentSearchQuery =>
      $$RecentSearchQueryTableTableManager(_db, _db.recentSearchQuery);
}
