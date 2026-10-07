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
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFav) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<bool>> toggleSubscribe(String c, bool s) async =>
      Result.error(Exception('x'));
  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
  }) async => Completer<Result<MediaStream>>().future;
}
