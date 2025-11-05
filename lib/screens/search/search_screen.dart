import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final VoidCallback? onBackClick;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.onBackClick,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearch() {
    /*final query = _controller.text.trim();
    if (query.isNotEmpty) {
      Provider.of<SearchProvider>(context, listen: false).search(query);
    }*/
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          hintText: 'Search',
          onChanged: (value) {
            // 处理搜索输入的逻辑
          },
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBackClick,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Search query: ${widget.initialQuery ?? 'No query'}'),
            ElevatedButton(
              onPressed: widget.onBackClick,
              child: const Text('pop'),
            ),
          ],
        ),
      ),
    );
  }
}
