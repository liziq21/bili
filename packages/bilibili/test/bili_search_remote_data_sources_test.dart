import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class MockNetworkSearchDataSource() implements NetworkSearchDataSource {
  String? lastCapturedQuery;

  static final _emptyResult = NetworkSearchResult.fromJson(const {
    'page': 1,
    'pagesize': 20,
    'numResults': 0,
    'numPages': 1,
    'result': {},
  });

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.positionalArguments.isNotEmpty) {
      lastCapturedQuery = invocation.positionalArguments.first as String;
    }
    return Future.value(_emptyResult);
  }
}

void main() {
  group('Bilibili Search Remote Data Sources Tests', () {
    late MockNetworkSearchDataSource mockNetwork;

    setUp(() {
      mockNetwork = MockNetworkSearchDataSource();
    });

    group('BiliVideoSearchRemoteDataSource', () {
      late BiliVideoSearchRemoteDataSource dataSource;

      setUp(() {
        dataSource = BiliVideoSearchRemoteDataSource(network: mockNetwork);
      });

      test('strips control characters from search video query', () async {
        final result = await dataSource.searchVideo(
          const SearchQuery(query: 'flut\r\nter\x00'),
        );
        expect(result, isA<Ok<Page<VideoModel>>>());
        expect(mockNetwork.lastCapturedQuery, equals('flutter'));
      });

      test(
        'returns empty Page when search video query is empty or whitespace',
        () async {
          final result = await dataSource.searchVideo(
            const SearchQuery(query: '   \r\n\x00'),
          );
          expect(result, isA<Ok<Page<VideoModel>>>());
          expect(mockNetwork.lastCapturedQuery, isNull);
          if (result case Ok(:final value)) {
            expect(value.data, isEmpty);
          }
        },
      );
    });

    group('BiliCreatorProfileSearchRemoteDataSource', () {
      late BiliCreatorProfileSearchRemoteDataSource dataSource;

      setUp(() {
        dataSource = BiliCreatorProfileSearchRemoteDataSource(
          network: mockNetwork,
        );
      });

      test('strips control characters from creator profile query', () async {
        final result = await dataSource.searchCreatorProfile(
          'up\r\nmaster\x1f',
        );
        expect(result, isA<Ok<Page<CreatorProfile>>>());
        expect(mockNetwork.lastCapturedQuery, equals('upmaster'));
      });

      test(
        'returns empty Page when creator profile query is empty or whitespace',
        () async {
          final result = await dataSource.searchCreatorProfile('\r\n   ');
          expect(result, isA<Ok<Page<CreatorProfile>>>());
          expect(mockNetwork.lastCapturedQuery, isNull);
          if (result case Ok(:final value)) {
            expect(value.data, isEmpty);
          }
        },
      );
    });

    group('BiliLiveRoomSearchRemoteDataSource', () {
      late BiliLiveRoomSearchRemoteDataSource dataSource;

      setUp(() {
        dataSource = BiliLiveRoomSearchRemoteDataSource(network: mockNetwork);
      });

      test('strips control characters from live room query', () async {
        final result = await dataSource.searchLiveRoom('live\x00stream\r\n');
        expect(result, isA<Ok<Page<LiveRoomModel>>>());
        expect(mockNetwork.lastCapturedQuery, equals('livestream'));
      });

      test(
        'returns empty Page when live room query is empty or whitespace',
        () async {
          final result = await dataSource.searchLiveRoom('\x7f\x00');
          expect(result, isA<Ok<Page<LiveRoomModel>>>());
          expect(mockNetwork.lastCapturedQuery, isNull);
          if (result case Ok(:final value)) {
            expect(value.data, isEmpty);
          }
        },
      );
    });

    group('BiliAggregateSearchRemoteDataSource', () {
      late BiliAggregateSearchRemoteDataSource dataSource;

      setUp(() {
        dataSource = BiliAggregateSearchRemoteDataSource(network: mockNetwork);
      });

      test('strips control characters from aggregate search query', () async {
        final result = await dataSource.searchAll('all\r\nin\x00one');
        expect(result, isA<Ok<AggregateSearchPage>>());
        expect(mockNetwork.lastCapturedQuery, equals('allinone'));
      });

      test('returns empty AggregateSearchPage when aggregate search query is empty or whitespace', () async {
        final result = await dataSource.searchAll(' \r\n ');
        expect(result, isA<Ok<AggregateSearchPage>>());
        expect(mockNetwork.lastCapturedQuery, isNull);
        if (result case Ok(:final value)) {
          expect(value.data, isEmpty);
          expect(value.creatorProfile, isNull);
          expect(value.creatorProfileVideos, isNull);
        }
      });
    });
  });
}
