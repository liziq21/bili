import 'package:flutter/material.dart';

void onSearchQueryChanged(String query) {
  print('搜索查询改变: $query');
  // 更新你的搜索状态，例如 setState(() => _currentSearchQuery = query);
}

void onSearchTriggered(String query) {
  print('搜索被触发: $query');
  // 执行搜索操作
}

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

class _SearchScreenState 
  extends State<SearchScreen>
  with SingleTickerProviderStateMixin
{
  late SearchController _searchController;
  late TabController _tabController;
  late FocusNode _searchfFocusNode;
  
  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    _searchfFocusNode = FocusNode();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.initialQuery?.trim().isNotEmpry ?? false) {
      _searchController.text = widget.initialQuery;
    } else {
      //_searchController.openView();
    }
    
    /*_searchController.addListener(() {
      // 忽略换行符逻辑
      if (_searchController.text.contains('\n')) {
        _searchController.text = _searchController.text.replaceAll('\n', '');
        _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length));
      }
      onSearchQueryChanged(_searchController.text);
      setState(() {}); // 触发 UI 更新以显示/隐藏清除按钮
    });*/

  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchfFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              clipBehavior: .none,
              shape: const StadiumBorder(),
              scrolledUnderElevation: 0.0,
              titleSpacing: 0.0,
              backgroundColor: .transparent,
              floating: true,
              snap: true,
              //centerTitle: false,
              title: Padding(
                padding: const EdgeInsets.all(8),
                child: SearchAnchor.bar(
                  searchController: _searchController,
                  barHintText: '搜索...',
                  suggestionsBuilder: (context, controller) {
                    return List<Widget>.generate(5, (index) {
                      return ListTile(
                        titleAlignment: ListTileTitleAlignment.center,
                        title: Text('Initial list item $index'),
                        onTap: () => controller.closeView('$index'),
                      );
                    });
                  },
                  textInputAction: .search,
                  onTap: () {
                    print('SearchAnchor bar tapped');
                  },
                  onChanged: (value) {},
                  //onSubmit: (value) => _searchController.closeView(value),
                ),
              ),
              bottom: TabBar(
                //controller: _tabController,
                tabs: const <Widget>[
                  Tab(
                    icon: Icon(.videocam_outlined),
                    text: 'Video',
                    iconMargin: EdgeInsets.only(bottom: 0.0),
                  ),
                  Tab(
                    icon: Icon(.photo_outlined),
                    text: 'Photos',
                    iconMargin: EdgeInsets.only(bottom: 0.0),
                  ),
                  Tab(
                    icon: Icon(.audiotrack_sharp),
                    text: 'Audio',
                    iconMargin: EdgeInsets.only(bottom: 0.0),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 100.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    itemBuilder: (BuildContext context, int index) {
                      return SizedBox(
                        width: 100.0,
                        child: Card(child: Center(child: Text('Card $index'))),
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(height: 1000, color: Colors.deepPurple.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),/*Center(
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
      ),*/
    );
  }
}



