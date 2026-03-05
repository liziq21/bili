import 'package:flutter/material.dart';


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
