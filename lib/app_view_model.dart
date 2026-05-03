import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
//import 'package:rxdart/rxdart.dart';

import 'data/model/user_data.dart';
import 'data/repository/user_data/user_data_repository.dart';
import 'utils/result.dart';
import 'utils/command.dart';

class ThemeState {
  const ThemeState(this.useDynamicColor, this.themeConfig);

  final bool useDynamicColor;
  final ThemeConfig themeConfig;

  @override
  bool operator ==(Object other) =>
      other is ThemeState &&
      other.useDynamicColor == useDynamicColor &&
      other.themeConfig == themeConfig;

  @override
  int get hashCode => Object.hash(useDynamicColor, themeConfig);
}

class AppViewModel extends ChangeNotifier {
  AppViewModel({required UserDataRepository userDataRepository})
    : _userDataRepository = userDataRepository {
    load = Command0(_load)..execute();
    _subscription = userDataRepository.data.listen((newUserData) {
      _userData = newUserData;
      notifyListeners();
    });
  }

  final _log = Logger('AppViewModel');
  final UserDataRepository _userDataRepository;
  late final Command0<UserData> load;
  late final StreamSubscription<UserData>? _subscription;
  late UserData _userData;

  UserData get userData => _userData;

  Future<Result<UserData>> _load() async {
    try {
      final data = await _userDataRepository.data.first;
      return .ok(data);
    } catch (e) {
      _log.warning('Failed to init', e);
      return .error(Exception('Load error'));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
