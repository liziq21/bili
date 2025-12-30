import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bili/search_type.dart';
import '../../data/model/recent_search_query.dart';
import 'search_view_model.dart';
import 'app_search_anchor_view_model.dart';

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({
    super.key,
    required this.viewModel,
    this.onBackClick,
  });

  final SearchViewModel viewModel;
  final AppSearchAnchorViewModel appSearchAnchorViewModel;
  final VoidCallback? onBackClick;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 1,
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
                  child: AppSearchAnchor(
                    viewModel: AppSearchAnchorViewModel(
                      getRecentSearchQueriesUseCase: context.read();
                      recentSearchQueryRepository: context.read();
                      searchSuggestRepository: context.read();
                    ),
                  ),
                ),
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: .start,
                  tabs: <Widget>[
                    Tab(
                      text: '综合',
                    ),
                    /*Tab(
                      text: '视频',
                    ),
                    Tab(
                      text: '直播',
                    ),
                    Tab(text: '用户',),*/
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
                    ChangeNotifierProvider(
                      create: (context) => AllSearchRuseltsViewModel(
                        searchQuery: searchQuery,
                        searchContentsRepository: context.read();
                      ),
                      child: AllSearchRuseltsView(),
                    ),
                    /*ChangeNotifierProvider(
                      create: (context) => TabViewModel('Tab 2'),
                      child: const TabContent(tabName: 'Tab 2'),
                    ),
                    ChangeNotifierProvider(
                      create: (context) => TabViewModel('Tab 3'),
                      child: const TabContent(tabName: 'Tab 3'),
                    ),*/
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> get _resultViews {
    
  }
}
