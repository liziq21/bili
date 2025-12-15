import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'preferences_data_source.dart';

List<SingleChildWidget> get datastoreProviders =>
  [
    Provider(create: (context) => PreferencesDataSource()),
  ];
