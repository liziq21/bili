import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/video_info_base.dart';
import 'app_search_anchor.dart';
import 'search_result_view_model.dart';
import 'search_view_model.dart';
import 'all_search_result.dart';
import 'video_search_result.dart';

import 'search_view_model.dart';

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({
    super.key,
    required this.viewModel,
    this.searchQuery,
    this.onBackClick,
  });

  final SearchViewModel viewModel;
  final VoidCallback? onBackClick;

  final String? searchQuery;

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Widget> _activeTabs = [];
  List<Widget> _activeViews = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final List<Widget> tabs = [];
    final List<Widget> views = [];

    if (context.read<AllSearchResultViewModel?>()
        case final AllSearchResultViewModel viewModel) {
      tabs.add(Tab(text: 'All'));
      views.add(AllSearchResult(viewModel: viewModel));
    }

    if (context.read<SearchResultViewModel<VideoInfoBase>?>()
        case final SearchResultViewModel<VideoInfoBase> viewModel) {
      tabs.add(Tab(text: 'Video'));
      views.add(VideoSearchResult(viewModel: viewModel));
    }

    setState(() {
      _activeTabs = tabs;
      _activeViews = views;
      _tabController = TabController(length: _activeTabs.length, vsync: this);
    });
  }

  @override
  void dispose() {
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
              //backgroundColor: Colors.transparent,
              floating: true,
              //pinned: true,
              snap: true,
              //centerTitle: false,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
                child: AppSearchAnchor(
                  recentSearchStream: widget.viewModel.recentSearchQueries,
                  fetchSuggests: widget.viewModel.getSuggests,
                  onSearch: (String query) {
                    widget.viewModel.updateRecentSearch(query);
                  },
                ),
              ),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: .start,
                tabs: _activeTabs,
              ),
            ),
            /*SliverToBoxAdapter(
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
              ),*/
            SliverToBoxAdapter(child: TabBarView(children: _activeViews)),
          ],
        ),
      ),
    );
  }
}

extension ProviderCheck on BuildContext {
  /// 检查是否存在类型为 T 的 Provider，且绝不触发对象实例化
  bool hasProvider<T>() {
    bool found = false;
    // visitAncestorElements 是最底层的方法，不会触发 InheritedWidget 的 get 逻辑
    this.visitAncestorElements((element) {
      final widget = element.widget;
      // 检查 Widget 是否是 InheritedProvider 且管理的类型匹配
      if (widget is InheritedProvider<T>) {
        found = true;
        return false; // 找到即停止遍历
      }
      return true; // 继续向上找
    });
    return found;
  }
}
