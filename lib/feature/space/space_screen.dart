import 'package:flutter/material.dart';

class SpaceScreen extends StatefulWidget {
  final VoidCallback? onBackClick;
  final String mid;
  
  const SpaceScreen({
    super.key,
    this.onBackClick,
    required this.mid,
  });

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {

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
      appBar: AppBar(title: const Text('Space')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(': ${widget.mid}'),
            ElevatedButton(
              onPressed: widget.onBackClick,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
