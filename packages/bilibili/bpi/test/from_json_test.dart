import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture(String name) {
    final file = File('test/fixtures/$name');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Fixture file test/fixtures/$name should exist',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

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
  });

  group('VideoDetailData fromJson tests', () {
    test('parses real video_detail.json correctly', () {
      final json = loadFixture('video_detail.json');
      final baseRes = BaseResponse.fromJson(json);

      expect(baseRes.code, equals(0));
      expect(baseRes.message, equals('OK'));
      expect(baseRes.data, isNotNull);

      final video = baseRes.data;
      expect(video.bvid, equals('BV1GJ411x7vy'));
      expect(video.aid, equals(80431228));
      expect(video.title, equals('教科书上的道具操作都有'));
      expect(video.owner.name, equals('风悄笔落'));
      expect(video.stat.view, greaterThan(0));
      expect(video.dimension.width, equals(1280));
      expect(video.dimension.height, equals(720));
      expect(video.isPageReversed, isFalse);
    });
  });
}
