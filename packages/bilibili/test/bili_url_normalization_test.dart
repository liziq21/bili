import 'dart:convert';
import 'dart:io';

import 'package:bilibili/src/bili_utils.dart';
import 'package:bilibili/src/data/model/creator_profile.dart';
import 'package:bilibili/src/data/model/video_model.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> loadFake(String key) {
  final candidatePaths = [
    'packages/bilibili/bpi/testing/$key.json',
    'bpi/testing/$key.json',
    'testing/$key.json',
  ];
  for (final path in candidatePaths) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Fake file $key not found');
}

void main() {
  group('normalizeBiliUrl tests', () {
    test('handles null and empty strings safely', () {
      expect(normalizeBiliUrl(null), isNull);
      expect(normalizeBiliUrl(''), isNull);
    });

    test('prefixes scheme-relative URLs with https:', () {
      expect(
        normalizeBiliUrl('//i0.hdslb.com/bfs/archive/pic.jpg'),
        equals('https://i0.hdslb.com/bfs/archive/pic.jpg'),
      );
    });

    test('converts http:// URLs to https://', () {
      expect(
        normalizeBiliUrl('http://i0.hdslb.com/bfs/archive/pic.jpg'),
        equals('https://i0.hdslb.com/bfs/archive/pic.jpg'),
      );
    });

    test('preserves already secure https:// URLs without duplication', () {
      expect(
        normalizeBiliUrl('https://i0.hdslb.com/bfs/archive/pic.jpg'),
        equals('https://i0.hdslb.com/bfs/archive/pic.jpg'),
      );
    });
  });

  group('buildBiliWatchUrl tests', () {
    test('builds valid watch URL for clean bvid', () {
      expect(
        buildBiliWatchUrl('BV1Deht6rEpZ'),
        equals('https://www.bilibili.com/video/BV1Deht6rEpZ'),
      );
    });

    test('strips control characters and whitespace from bvid', () {
      expect(
        buildBiliWatchUrl('  BV1Deht6rEpZ\r\n\x00 '),
        equals('https://www.bilibili.com/video/BV1Deht6rEpZ'),
      );
    });
  });

  group('Model DTO URL normalization tests', () {
    test(
      'NetworkVideoSearchResultX.asModel normalizes thumbnailUrl from fixture',
      () {
        final json = loadFake('search_video');
        final data = json['data'] as Map<String, dynamic>;
        final result = NetworkSearchResult.fromJson(data);
        final video = result.result.video.first;

        final model = video.asModel();
        expect(model.thumbnailUrl, isNotNull);
        expect(model.thumbnailUrl, startsWith('https://'));
        expect(model.thumbnailUrl, isNot(startsWith('https:https://')));
      },
    );

    test(
      'NetworkLiveUserSearchResultX.asModel normalizes thumbnailUrl from fixture',
      () {
        final json = loadFake('search_live');
        final data = json['data'] as Map<String, dynamic>;
        final result = NetworkSearchResult.fromJson(data);
        final liveUser = result.result.liveUser.first;

        final model = liveUser.asModel();
        expect(model.thumbnailUrl, isNotNull);
        expect(model.thumbnailUrl, startsWith('https://'));
        expect(model.thumbnailUrl, isNot(startsWith('https:https://')));
      },
    );

    test('NetworkVideoSearchResultX.asModel normalizes video url to https', () {
      final json = loadFake('search_video');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);
      final video = result.result.video.first;

      final model = video.asModel();
      expect(model.url, startsWith('https://'));
      expect(model.url, isNot(startsWith('https:https://')));
    });

    test('NetworkVideoSearchResultX.asModel handles http and empty arcurl', () {
      final json = loadFake('search_video');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);
      final rawVideo = result.result.video.first;

      final httpVideo = NetworkVideoSearchResult(
        id: rawVideo.id,
        author: rawVideo.author,
        mid: rawVideo.mid,
        typeid: rawVideo.typeid,
        typename: rawVideo.typename,
        arcurl: 'http://www.bilibili.com/video/av12345678',
        aid: rawVideo.aid,
        bvid: rawVideo.bvid,
        title: rawVideo.title,
        description: rawVideo.description,
        pic: rawVideo.pic,
        play: rawVideo.play,
        favorites: rawVideo.favorites,
        tag: rawVideo.tag,
        review: rawVideo.review,
        pubdate: rawVideo.pubdate,
        senddate: rawVideo.senddate,
        duration: rawVideo.duration,
        badgepay: rawVideo.badgepay,
        isUnionVideo: rawVideo.isUnionVideo,
        like: rawVideo.like,
        upic: rawVideo.upic,
        corner: rawVideo.corner,
        cover: rawVideo.cover,
        desc: rawVideo.desc,
        url: rawVideo.url,
        danmaku: rawVideo.danmaku,
      );
      expect(
        httpVideo.asModel().url,
        equals('https://www.bilibili.com/video/av12345678'),
      );

      final emptyVideo = NetworkVideoSearchResult(
        id: rawVideo.id,
        author: rawVideo.author,
        mid: rawVideo.mid,
        typeid: rawVideo.typeid,
        typename: rawVideo.typename,
        arcurl: '',
        aid: rawVideo.aid,
        bvid: rawVideo.bvid,
        title: rawVideo.title,
        description: rawVideo.description,
        pic: rawVideo.pic,
        play: rawVideo.play,
        favorites: rawVideo.favorites,
        tag: rawVideo.tag,
        review: rawVideo.review,
        pubdate: rawVideo.pubdate,
        senddate: rawVideo.senddate,
        duration: rawVideo.duration,
        badgepay: rawVideo.badgepay,
        isUnionVideo: rawVideo.isUnionVideo,
        like: rawVideo.like,
        upic: rawVideo.upic,
        corner: rawVideo.corner,
        cover: rawVideo.cover,
        desc: rawVideo.desc,
        url: rawVideo.url,
        danmaku: rawVideo.danmaku,
      );
      expect(
        emptyVideo.asModel().url,
        equals('https://www.bilibili.com/video/${rawVideo.bvid}'),
      );
    });

    test('NetworkBiliUserResX.asModel normalizes video url to https', () {
      final json = loadFake('search_bili_user');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);
      final user = result.result.biliUser.first;
      final video = user.res.first;

      final model = video.asModel();
      expect(model.url, startsWith('https://'));
      expect(model.url, isNot(startsWith('https:https://')));
    });

    test('NetworkBiliPopularVideoX sanitizes bvid control chars', () {
      final popularVideo = NetworkBiliPopularVideo(
        aid: 12345,
        bvid: '  BV1Deht6rEpZ\r\n\x00 ',
        title: 'Popular Test',
      );
      final model = popularVideo.asModel();
      final expected = 'https://www.bilibili.com/video/BV1Deht6rEpZ';
      expect(model.url, expected);
    });
  });
}
