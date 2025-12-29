import 'dart:async';

import '../../../utils/result.dart';
import '../../model/video_info_base.dart';

abstract class SearchContentsRepository {
  Future<Result<List<VideoInfoBase>>> searchContents(String searchQuery);
}