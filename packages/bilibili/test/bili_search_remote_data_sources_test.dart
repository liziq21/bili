import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class MockNetworkSearchDataSource() implements NetworkSearchDataSource {
  String? lastCapturedQuery;
  Map<Symbol, dynamic>? lastNamedArguments;

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
    lastNamedArguments = invocation.namedArguments;
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
        expect(result, isA<Success<Page<VideoModel>, Exception>>());
        expect(mockNetwork.lastCapturedQuery, equals('flutter'));
      });

      test('passes the selected sort and duration to the network', () async {
        await dataSource.searchVideo(
          SearchQuery(
            query: 'flutter',
            sortOption: PhotoOrVideoSearchSort.pubdate,
            filters: [
              const VideoDurationFilter().copyWith(
                selection: VideoDurationFilterOption.tenTo30Minutes,
              ),
            ],
          ),
        );

        expect(mockNetwork.lastNamedArguments?[#order], 'pubdate');
        expect(mockNetwork.lastNamedArguments?[#duration], '2');
      });

      test(
        'omits the duration parameter for the all-duration option',
        () async {
          await dataSource.searchVideo(const SearchQuery(query: 'flutter'));

          expect(mockNetwork.lastNamedArguments?[#order], isNull);
          expect(mockNetwork.lastNamedArguments?[#duration], isNull);
        },
      );

      test(
        'returns empty Page when search video query is empty or whitespace',
        () async {
          final result = await dataSource.searchVideo(
            const SearchQuery(query: '   \r\n\x00'),
          );
          expect(result, isA<Success<Page<VideoModel>, Exception>>());
          expect(mockNetwork.lastCapturedQuery, isNull);
          if (result case Success(:final success)) {
            expect(success.data, isEmpty);
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
        expect(result, isA<Success<Page<CreatorProfile>, Exception>>());
        expect(mockNetwork.lastCapturedQuery, equals('upmaster'));
      });

      test(
        'returns empty Page when creator profile query is empty or whitespace',
        () async {
          final result = await dataSource.searchCreatorProfile('\r\n   ');
          expect(result, isA<Success<Page<CreatorProfile>, Exception>>());
          expect(mockNetwork.lastCapturedQuery, isNull);
          if (result case Success(:final success)) {
            expect(success.data, isEmpty);
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
        expect(result, isA<Success<Page<LiveRoomModel>, Exception>>());
        expect(mockNetwork.lastCapturedQuery, equals('livestream'));
      });

      test(
        'returns empty Page when live room query is empty or whitespace',
        () async {
          final result = await dataSource.searchLiveRoom('\x7f\x00');
          expect(result, isA<Success<Page<LiveRoomModel>, Exception>>());
          expect(mockNetwork.lastCapturedQuery, isNull);
          if (result case Success(:final success)) {
            expect(success.data, isEmpty);
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
        expect(result, isA<Success<AggregateSearchPage, Exception>>());
        expect(mockNetwork.lastCapturedQuery, equals('allinone'));
      });

      test('returns empty AggregateSearchPage when aggregate search query is empty or whitespace', () async {
        final result = await dataSource.searchAll(' \r\n ');
        expect(result, isA<Success<AggregateSearchPage, Exception>>());
        expect(mockNetwork.lastCapturedQuery, isNull);
        if (result case Success(:final success)) {
          expect(success.data, isEmpty);
          expect(success.creatorProfile, isNull);
          expect(success.creatorProfileVideos, isNull);
        }
      });
    });
  });
}
