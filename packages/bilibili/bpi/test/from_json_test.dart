import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture(String name) {
    final file = File('testing/$name');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Fixture file testing/$name should exist',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  group('HtmlTitle sanitization tests', () {
    test('strips em keyword tags correctly from search title', () {
      final title = HtmlTitle.fromJson('<em class="keyword">Flutter</em> 教程');
      expect(title.parsedTitle(), equals('Flutter 教程'));
    });

    test('strips malicious or arbitrary html tags safely', () {
      final title = HtmlTitle.fromJson('<script>alert(1)</script><b>Title</b>');
      expect(title.parsedTitle(), equals('Title'));
    });

    test('handles empty or null json gracefully', () {
      final titleNull = HtmlTitle.fromJson(null);
      expect(titleNull.parsedTitle(), equals(''));

      final titleEmpty = HtmlTitle.fromJson('');
      expect(titleEmpty.parsedTitle(), equals(''));
    });
  });

  group('NetworkSearchSuggest fromJson tests', () {
    test('parses real search_suggest.json correctly', () {
      final json = loadFixture('search_suggest.json');
      final suggest = NetworkSearchSuggest.fromJson(json);

      expect(suggest.tag, isNotEmpty);
      final first = suggest.tag.first;
      expect(first.term, isNotEmpty);
      expect(first.name, isNotEmpty);
    });
  });

  group('NetworkSearchResult fromJson tests', () {
    test('parses real search_all.json correctly', () {
      final json = loadFixture('search_all.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.page, equals(1));
      expect(result.pagesize, greaterThan(0));
      expect(result.numResults, greaterThan(0));
      expect(result.result, isNotNull);
    });

    test('parses real search_video.json correctly', () {
      final json = loadFixture('search_video.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.video, isNotEmpty);
      final video = result.result.video.first;
      expect(video.bvid, isNotEmpty);
      expect(video.author, isNotEmpty);
      expect(video.title.text, isNotEmpty);
      expect(video.play, greaterThanOrEqualTo(0));
    });

    test('parses real search_bili_user.json correctly', () {
      final json = loadFixture('search_bili_user.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.biliUser, isNotEmpty);
      final user = result.result.biliUser.first;
      expect(user.uname, isNotEmpty);
      expect(user.mid, greaterThan(0));
    });

    test('parses real search_live.json correctly', () {
      final json = loadFixture('search_live.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.numResults, greaterThanOrEqualTo(0));
    });

    test('parses real search_live_room.json correctly', () {
      final json = loadFixture('search_live_room.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.page, equals(1));
    });

    test('parses real search_live_user.json correctly', () {
      final json = loadFixture('search_live_user.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.page, equals(1));
      expect(result.result.liveUser, isNotEmpty);
      final liveUser = result.result.liveUser.first;
      expect(liveUser.uname.text, isNotEmpty);
      expect(liveUser.roomid, greaterThan(0));
    });

    test('parses real search_article.json correctly', () {
      final json = loadFixture('search_article.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.article, isNotEmpty);
      final article = result.result.article.first;
      expect(article.title.text, isNotEmpty);
      expect(article.id, greaterThan(0));
    });

    test('parses real search_media_bangumi.json correctly', () {
      final json = loadFixture('search_media_bangumi.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.mediaBangumi, isNotEmpty);
      final bangumi = result.result.mediaBangumi.first;
      expect(bangumi.title.text, isNotEmpty);
      expect(bangumi.mediaId, greaterThan(0));
    });

    test('parses real search_media_ft.json correctly', () {
      final json = loadFixture('search_media_ft.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.page, equals(1));
    });

    test('handles search_photo.json correctly', () {
      final json = loadFixture('search_photo.json');
      if (json['data'] is Map<String, dynamic>) {
        final result = NetworkSearchResult.fromJson(
          json['data'] as Map<String, dynamic>,
        );
        expect(result.page, greaterThanOrEqualTo(1));
      } else {
        expect(json['code'], isNot(equals(0)));
      }
    });

    test('handles search_topic.json correctly', () {
      final json = loadFixture('search_topic.json');
      if (json['data'] is Map<String, dynamic>) {
        final result = NetworkSearchResult.fromJson(
          json['data'] as Map<String, dynamic>,
        );
        expect(result.page, greaterThanOrEqualTo(1));
      } else {
        expect(json['code'], isNot(equals(0)));
      }
    });
  });
}
