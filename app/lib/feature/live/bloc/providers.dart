import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repository/app_live_room_repository.dart';
import '../../../datastore/preferences_data_source.dart';
import 'live_bloc.dart';

List<BlocProvider> getLiveBlocProviders(
  BuildContext context, {
  required int roomId,
}) {
  final repo = context.read<AppLiveRoomRepository?>();
  if (repo == null) return const [];

  final preferences = context.read<PreferencesDataSource?>();

  return [
    BlocProvider<LiveBloc>(
      create: (_) => LiveBloc(repository: repo, preferences: preferences)
        ..add(LoadLiveRoomDetail(roomId))
        ..add(LoadLiveStream(roomId)),
    ),
  ];
}
