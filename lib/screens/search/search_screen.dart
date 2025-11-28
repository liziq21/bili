import 'package:flutter/material.dart';

import '../../bili/search_type.dart';
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
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                clipBehavior: .none,
                shape: const StadiumBorder(),
                scrolledUnderElevation: 0.0,
                titleSpacing: 0.0,
                //backgroundColor: Colors.transparent,
                //floating: true,
                //pinned: true,
                //snap: true,
                //centerTitle: false,
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
                  child: FocusScope(
                    descendantsAreFocusable: false,
                    child: SearchAnchor.bar(
                      searchController: viewModel.searchController,
                      barHintText: '搜索...',
                      suggestionsBuilder: (context, controller) {
                        if (controller.text.isEmpty) {
                          /*if (searchHistory.isNotEmpty) {
                            return getHistoryList(controller);
                          }*/
                          return <Widget>[
                            const Center(
                              child: Text(
                                'No search history.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ];
                        }
                        //return getSuggestions(controller);
                        return List<Widget>.generate(5, (index) {
                          return ListTile(
                            titleAlignment: ListTileTitleAlignment.center,
                            title: Text('No search suggestion. $index'),
                            onTap: () => viewModel.onSearchTriggered('$index'),
                          );
                        });
                      },
                      textInputAction: .search,
                      //onTap: () {},
                      onChanged: viewModel.onChanged,
                      onSubmit: viewModel.onSearchTriggered,
                    ),
                  ),
                ),
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: <Widget>[
                    Tab(
                      text: '视频',
                      //iconMargin: EdgeInsets.only(bottom: 0.0),
                    ),
                    Tab(
                      text: '番剧',
                      iconMargin: EdgeInsets.only(bottom: 0.0),
                    ),
                    Tab(
                      text: '影视',
                      iconMargin: EdgeInsets.only(bottom: 0.0),
                    ),
                    Tab(
                      text: '直播',
                      iconMargin: EdgeInsets.only(bottom: 0.0),
                    ),
                    Tab(
                      text: '用户',
                      iconMargin: EdgeInsets.only(bottom: 0.0),
                    ),
                    Tab(
                      text: '专栏',
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
                child: TabBarView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1000, color: Colors.pinkAccent.withOpacity(0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1000, color: Colors.deepPurple.withOpacity(0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1000, color: Colors.pinkAccent.withOpacity(0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1000, color: Colors.deepPurple.withOpacity(0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1000, color: Colors.pinkAccent.withOpacity(0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1000, color: Colors.deepPurple.withOpacity(0.5)),
                    ),
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
