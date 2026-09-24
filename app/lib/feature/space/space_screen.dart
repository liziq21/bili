import 'package:material_ui/material_ui.dart';

class const SpaceScreen({
  super.key,
  final VoidCallback? onBackClick,
  required final String mid,
}) extends StatefulWidget {
  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState() extends State<SpaceScreen> {
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
