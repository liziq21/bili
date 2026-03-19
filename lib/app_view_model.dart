import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import 'data/model/user_data.dart';
import 'data/repository/user_data/user_data_repository.dart';
import 'utils/result.dart';

class AppViewModel {
  AppViewModel({
    required UserDataRepository userDataRepository,
  }) : _userDataRepository = userDataRepository,
       dynamicColorStream = userDataRepository.data
         .map((data) => data.shouldUseDynamicColor)
         .distinct()
         .shareReplay(maxSize: 1),
       themeConfigStream = userDataRepository.data
         .map((data) => data.themeConfig)
         .distinct()
         .shareReplay(maxSize: 1) {
    load = Command0(_load)..execute();
  }
  
  final _log = Logger('AppViewModel');
  final UserDataRepository _userDataRepository;
  final Stream<bool> dynamicColorStream;
  final Stream<ThemeConfig> themeConfigStream;
  late final Command0 load;
  
  Futrue<Result<void>> _load() async {
    try {
      await _userDataRepository.data.first;
      return .ok();
    } catch (e) {
      _log.warning('Failed to init', e);
      return .error(Exception('Load error'));
    }
  }
  
}

