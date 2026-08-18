import 'package:flutter/material.dart';

class VideoParameters {
  
  const VideoParameters({
    required this.id,
    this.cid,
    this.commentRootId,
    this.commentSecondaryId,
    this.dmProgress,
  });
  final String id;
  final String? cid;
  final String? commentRootId;
  final String? commentSecondaryId;
  final String? dmProgress;
}

class VideoScreen extends StatefulWidget {
  
  const VideoScreen({
    super.key,
    this.onBackClick,
    required this.parameters,
  });
  final VoidCallback? onBackClick;
  final VideoParameters parameters;

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {

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
      appBar: AppBar(title: const Text('Video')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('id: ${widget.parameters.id}'),
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
