import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../database/dao/creator_profile_dao.dart';
import 'search_contents_repository.dart';

abstract interface class CreatorProfileRepository() {
  Future<Result<CreatorProfile, Exception>> getProfile(String id);
}

class const AppCreatorProfileRepository(
  final String _sourceId,
  final CreatorProfileDao _creatorProfileDao,
  final CreatorProfileSearchRepository? _searchRepository,
  final CreatorProfileRemoteDataSource? _profileDataSource,
) implements CreatorProfileRepository {
  @override
  Future<Result<CreatorProfile, Exception>> getProfile(String id) async {
    final cachedProfile = await _creatorProfileDao.getCreatorProfile(
      _sourceId,
      id,
    );
    if (cachedProfile != null) return Result.success(cachedProfile.asModel());

    if (_profileDataSource case final profileDataSource?) {
      final direct = await profileDataSource.getProfile(id);
      switch (direct) {
        case Success(:final success):
          await _creatorProfileDao.cacheCreatorProfile(_sourceId, success);
          return Result.success(success);
        case Error(:final error):
          // 限流时不再退回搜索：搜索端点与搜索页共用更紧的额度，再打一次只会
          // 让冷却更久；把失败原样交给界面判档。
          if (error is RateLimitedFailure) return Result.error(error);
      }
    }

    final searchRepository = _searchRepository;
    if (searchRepository == null) {
      return Result.error(Exception('Creator profile source unavailable'));
    }
    final result = await searchRepository.search(SearchQuery(query: id));
    return switch (result) {
      Success(:final success) => await _cacheRemoteProfile(success, id),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<CreatorProfile, Exception>> _cacheRemoteProfile(
    Page<CreatorProfile> page,
    String requestedId,
  ) async {
    CreatorProfile? profile;
    for (final candidate in page.data) {
      if (candidate.id == requestedId) {
        profile = candidate;
        break;
      }
    }
    if (profile == null) {
      return Result.error(Exception('Creator profile not found'));
    }

    await _creatorProfileDao.cacheCreatorProfile(_sourceId, profile);
    return Result.success(profile);
  }
}
