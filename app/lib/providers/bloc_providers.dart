import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';

List<BlocProvider> getBlocProviders(BuildContext context) => [
  BlocProvider<AppBloc>(
    create: ((context) {
      return .new(userDataRepository: context.read());
    }),
  ),
];
