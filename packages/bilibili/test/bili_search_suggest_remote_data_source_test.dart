import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class MockNetworkSearchDataSource() implements NetworkSearchDataSource {
  String? lastCapturedTerm;
  NetworkSearchSuggest suggestResponse = const NetworkSearchSuggest(tag: []);

  @override
  Future<NetworkSearchSuggest> getSuggests(String term) async {
    lastCapturedTerm = term;
    return suggestResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BiliSearchSuggestRemoteDataSource tests', () {
    late MockNetworkSearchDataSource mockNetwork;
    late BiliSearchSuggestRemoteDataSource dataSource;

    setUp(() {
      mockNetwork = MockNetworkSearchDataSource();
      dataSource = BiliSearchSuggestRemoteDataSource(network: mockNetwork);
    });

    test(
      'strips control characters from input query and fetches suggestions',
      () async {
        mockNetwork.suggestResponse = const NetworkSearchSuggest(
          tag: [
            NetworkSearchSuggestItem(term: 'flutter', name: 'flutter'),
          ],
        );

        final result = await dataSource.getSuggests('flut\r\nter\x00');
        expect(result, isA<Ok<List<String>>>());
        expect(mockNetwork.lastCapturedTerm, equals('flutter'));
        if (result case Ok(:final value)) {
          expect(value, equals(['flutter']));
        }
      },
    );

    test(
      'returns empty list immediately when query only contains control chars',
      () async {
        final result = await dataSource.getSuggests('\r\n\x00\x1f');
        expect(result, isA<Ok<List<String>>>());
        expect(mockNetwork.lastCapturedTerm, isNull);
        if (result case Ok(:final value)) {
          expect(value, isEmpty);
        }
      },
    );

    test(
      'strips HTML tags and control characters from returned suggest terms',
      () async {
        mockNetwork.suggestResponse = const NetworkSearchSuggest(
          tag: [
            NetworkSearchSuggestItem(
              term: '<em class="keyword">flutter</em>\r\n',
              name: 'flutter',
            ),
            NetworkSearchSuggestItem(
              term: '<b>dart</b>\x00',
              name: 'dart',
            ),
          ],
        );

        final result = await dataSource.getSuggests('flutter');
        expect(result, isA<Ok<List<String>>>());
        if (result case Ok(:final value)) {
          expect(value, equals(['flutter', 'dart']));
        }
      },
    );
  });
}
