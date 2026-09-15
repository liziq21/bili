import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/home_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onLive,
    required this.navigateToSearchReault,
    required this.onSpace,
    required this.onVideo,
  });

  final Function(String roomId) onLive;
  final Function(String searchQuery) navigateToSearchReault;
  final Function(String mid) onSpace;
  final Function(String id) onVideo;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _availableSources = ['bilibili', 'youtube'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return DropdownButton<String>(
              value: state.sourceId,
              underline: const SizedBox.shrink(),
              items: _availableSources.map((source) {
                final label = switch (source.toLowerCase()) {
                  'bilibili' => 'Bilibili',
                  'youtube' => 'YouTube',
                  _ => source,
                };
                return DropdownMenuItem<String>(
                  value: source,
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (String? newSource) {
                if (newSource != null) {
                  context.read<HomeBloc>().add(ServiceSourceChanged(newSource));
                }
              },
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => widget.onLive('230023'),
              child: const Text('Live'),
            ),
            ElevatedButton(
              onPressed: () => widget.navigateToSearchReault('da'),
              child: const Text('Search "da"'),
            ),
            ElevatedButton(
              onPressed: () => widget.onSpace('188339'),
              child: const Text('Space'),
            ),
            ElevatedButton(
              onPressed: () => widget.onVideo('33'),
              child: const Text('Video'),
            ),
          ],
        ),
      ),
    );
  }
}
