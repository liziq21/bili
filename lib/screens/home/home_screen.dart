import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  final Function(String roomId) onLive;
  final Function(String? query) onSearch;
  final Function(String mid) onSpace;
  final Function(String id) onVideo;
  
  const HomeScreen({
    super.key,
    required this.onLive,
    required this.onSearch,
    required this.onSpace,
    required this.onVideo,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => widget.onLive('230023'),
              child: const Text('Live'),
            ),
            ElevatedButton(
              onPressed: () => widget.onSearch('query'),
              child: const Text('Search'),
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
