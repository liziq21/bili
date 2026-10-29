import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

import 'dart:async';

void main() {
  test('close no events', () async {
    final bloc = VideoBloc(repository: _Repo());
    await bloc.close();
    expect(bloc.isClosed, isTrue);
  });
}

class _Repo() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<bool, Exception>> toggleFavorite(String id, bool isFav) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<bool, Exception>> toggleSubscribe(String c, bool s) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Completer<Result<MediaStream, Exception>>().future;
}
