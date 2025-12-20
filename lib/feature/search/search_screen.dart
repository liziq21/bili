import 'package:flutter/material.dart';

import '../../bili/search_type.dart';
import '../../data/model/recent_search_query.dart';
import 'search_view_model.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.viewModel,
    this.onBackClick,
  });

  final SearchViewModel viewModel;
  final VoidCallback? onBackClick;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 6,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                clipBehavior: .none,
                shape: const StadiumBorder(),
                scrolledUnderElevation: 0.0,
                titleSpacing: 0.0,
                //backgroundColor: Colors.transparent,
                floating: true,
                //pinned: true,
                snap: true,
                //centerTitle: false,
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
                  child: FocusScope(
                    descendantsAreFocusable: false,
                    child: SearchAnchor.bar(
                      searchController: widget.viewModel.searchController,
                      barHintText: '搜索...',
                      barElevation: .all(0.0),
                      suggestionsBuilder: (context, controller) async {
                        if (controller.text.isEmpty) {
                          StreamBuilder<List<RecentSearchQuery>>(
                            stream: widget.viewModel.recentSearchQueries,
                            builder: (context, snapshot) {
                              return switch (snapshot) {
                                AsyncSnapshot(hasError: true) => Text(
                                  snapshot.error.toString(),
                                ),
                                AsyncSnapshot(hasData: true) => AsyncSnapshot.data!.isEmpty
                                  ? <Widget>[
                                      const Center(
                                        child: Text(
                                          'No search history.',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ]
                                  : AsyncSnapshot.data!.map((recentSearchQuery) =>
                                      ListTile(
                                        titleAlignment: ListTileTitleAlignment.center,
                                        leading: const Icon(Icons.history),
                                        title: Text(recentSearchQuery.query),
                                        onTap: () => widget.viewModel.onSearchTriggered(recentSearchQuery.query),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.north_west),
                                          onPressed: () => controller.text = recentSearchQuery.query,
                                        ),
                                      )
                                    ),
                                _ => Text('No Data', style: textStyle),
                              };
                            },
                          return ;
                        }
                    
                        final suggests = await widget.viewModel.getSuggests(controller.text);
                        return suggests.map((suggest) =>
                          ListTile(
                            titleAlignment: ListTileTitleAlignment.center,
                            leading: const Icon(Icons.public),
                            title: Text(suggest),
                            onTap: () => widget.viewModel.onSearchTriggered(suggest),
                            trailing: IconButton(
                              icon: const Icon(Icons.north_west),
                              onPressed: () => controller.text = suggest,
                            ),
                          )
                        );
                      },
                      textInputAction: .search,
                      //onTap: () {},
                      onSubmitted: widget.viewModel.onSearchTriggered,
                    ),
                  ),
                ),
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: .start,
                  tabs: <Widget>[
                    Tab(
                      text: '视频',
                    ),
                    Tab(
                      text: '番剧',
                    ),
                    Tab(
                      text: '影视',
                    ),
                    Tab(
                      text: '直播',
                    ),
                    Tab(
                      text: '用户',
                    ),
                    Tab(
                      text: '专栏',
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
                child: TabBarView(
                  children: [
                    const Text('1'),
                    const Text('2'),
                    const Text('3'),
                    const Text('4'),
                    const Text('5'),
                    const Text('6'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
