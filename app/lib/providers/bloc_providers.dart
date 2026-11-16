import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';

List<BlocProvider> get blocProviders => [
  BlocProvider<AppBloc>(
    create: ((context) => .new(userDataRepository: context.read())),
  ),
];
