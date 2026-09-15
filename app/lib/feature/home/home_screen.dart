import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import 'bloc/home_bloc.dart';

class const HomeScreen({
  super.key,
  required final Function(String roomId) onLive,
  required final Function(String searchQuery) navigateToSearchReault,
  required final Function(String mid) onSpace,
  required final Function(String id) onVideo,
}) extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      widget.navigateToSearchReault(trimmed);
    }
  }

  Future<void> _showIdInputDialog({
    required BuildContext context,
    required String title,
    required String labelText,
    required String hintText,
    required String defaultId,
    required ValueChanged<String> onSubmit,
  }) async {
    final controller = TextEditingController(text: defaultId);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: $styles.text.h3.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labelText,
              style: $styles.text.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: $styles.insets.xs),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (val) => Navigator.of(context).pop(val.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSubmit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = context.mediaSources;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: $styles.insets.sm,
        title: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final effectiveSourceId =
                sources.any((s) => s.id == state.sourceId)
                    ? state.sourceId
                    : (sources.isNotEmpty ? sources.first.id : state.sourceId);

            final activeSource = sources.firstWhere(
              (s) => s.id == effectiveSourceId,
              orElse: () => sources.first,
            );

            return Container(
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular($styles.corners.lg),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: $styles.insets.xs),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveSourceId,
                        isDense: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        items: sources.map((source) {
                          return DropdownMenuItem<String>(
                            value: source.id,
                            child: Text(
                              source.name,
                              style: $styles.text.title2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newSource) {
                          if (newSource != null) {
                            context
                                .read<HomeBloc>()
                                .add(ServiceSourceChanged(newSource));
                          }
                        },
                      ),
                    ),
                  ),
                  VerticalDivider(
                    indent: 10,
                    endIndent: 10,
                    width: $styles.insets.sm,
                    color: colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _onSearchSubmitted,
                      textInputAction: TextInputAction.search,
                      textAlignVertical: TextAlignVertical.center,
                      style: $styles.text.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '搜索 ${activeSource.name} 内容...',
                        hintStyle: $styles.text.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: $styles.insets.xs,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _onSearchSubmitted(_searchController.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final effectiveSourceId =
              sources.any((s) => s.id == state.sourceId)
                  ? state.sourceId
                  : (sources.isNotEmpty ? sources.first.id : state.sourceId);

          final activeSource = sources.firstWhere(
            (s) => s.id == effectiveSourceId,
            orElse: () => sources.first,
          );

          final hasSearch =
              activeSource.videoSearchDataSource != null ||
              activeSource.aggregateSearchDataSource != null;
          final hasCreator = activeSource.creatorProfileSearchDataSource != null;
          final hasLive = activeSource.liveRoomSearchDataSource != null;
          final hasVideoDetail = activeSource.videoDetailDataSource != null;

          final cards = <Widget>[
            if (hasSearch)
              _FeatureCard(
                icon: Icons.search_rounded,
                title: '搜索探索',
                subtitle: '在 ${activeSource.name} 探索视频、创作者或相关内容',
                onTap: () => _onSearchSubmitted(_searchController.text),
              ),
            if (hasCreator)
              _FeatureCard(
                icon: Icons.account_circle_rounded,
                title: activeSource.id == 'bilibili' ? 'UP主空间' : '创作者频道',
                subtitle: '输入 ${activeSource.name} 创作者/用户 ID 访问个人空间',
                onTap: () {
                  _showIdInputDialog(
                    context: context,
                    title: activeSource.id == 'bilibili' ? '访问 UP主空间' : '访问创作者频道',
                    labelText: '请输入 MID 或频道 ID：',
                    hintText: activeSource.id == 'bilibili' ? '例如 188339' : '频道 ID',
                    defaultId: activeSource.id == 'bilibili' ? '188339' : '',
                    onSubmit: (id) => widget.onSpace(id),
                  );
                },
              ),
            if (hasLive)
              _FeatureCard(
                icon: Icons.live_tv_rounded,
                title: '直播大厅',
                subtitle: '输入 ${activeSource.name} 直播间 ID 快速进入直播',
                onTap: () {
                  _showIdInputDialog(
                    context: context,
                    title: '进入直播间',
                    labelText: '请输入直播间 ID：',
                    hintText: '例如 230023',
                    defaultId: '230023',
                    onSubmit: (id) => widget.onLive(id),
                  );
                },
              ),
            if (hasVideoDetail)
              _FeatureCard(
                icon: Icons.play_circle_fill_rounded,
                title: '视频播放',
                subtitle: '输入 ${activeSource.name} 视频 ID 快速查看详情与播放',
                onTap: () {
                  _showIdInputDialog(
                    context: context,
                    title: '播放视频',
                    labelText: '请输入视频 ID (如 BV/AV 号)：',
                    hintText: '例如 33',
                    defaultId: '33',
                    onSubmit: (id) => widget.onVideo(id),
                  );
                },
              ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);

              return SingleChildScrollView(
                padding: EdgeInsets.all($styles.insets.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${activeSource.name} 功能导航',
                      style: $styles.text.h3.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: $styles.insets.xs),
                    Text(
                      '根据当前服务源可用能力动态展示可用功能',
                      style: $styles.text.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: $styles.insets.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 104.0,
                        crossAxisSpacing: $styles.insets.sm,
                        mainAxisSpacing: $styles.insets.sm,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) => cards[index],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class const _FeatureCard({
  required final IconData icon,
  required final String title,
  required final String subtitle,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular($styles.corners.md),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular($styles.corners.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: $styles.insets.sm,
            vertical: $styles.insets.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all($styles.insets.xs),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular($styles.corners.sm),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              SizedBox(width: $styles.insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: $styles.text.bodyBold.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: $styles.insets.xxs),
                    Text(
                      subtitle,
                      style: $styles.text.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
