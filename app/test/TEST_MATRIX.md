# 测试分类矩阵

每个 `*_test.dart` 按其**实际行为**（而非目录）归入六类。
本文件由 `tool/test_matrix.py --report` 生成，勿手改；
改分类请改脚本内的 `TEST_MATRIX` 映射后重新生成。

| 分类 | 文件数 |
|------|--------|
| unit | 63 |
| widget | 45 |
| golden | 8 |
| contract | 12 |
| integration | 2 |
| performance | 0 |
| **合计** | **130** |

## 分类定义

- **unit**：纯 Dart 逻辑，`test()` 驱动，不 pump widget
- **widget**：`testWidgets` + `WidgetTester`，无 golden 断言
- **golden**：alchemist `goldenTest()` 场景，断言像素基线
- **contract**：护栏/契约类——硬编码文案、字体子集、设计令牌、
  fixture 映射表、路由表结构等跨文件结构约束
- **integration**：跨层组合（app 启动接线、全壳冒烟）
- **performance**：帧率/耗时基准（当前无文件）

## unit（63）

- `app/test/data/local_library_repository_test.dart`
- `app/test/data/repository/creator_profile_repository_test.dart`
- `app/test/data/repository/video_comment_repository_test.dart`
- `app/test/data/repository/video_detail_repository_test.dart`
- `app/test/database/app_database_test.dart`
- `app/test/database/local_library_dao_test.dart`
- `app/test/database/local_media_key_test.dart`
- `app/test/database/local_playlist_dao_test.dart`
- `app/test/database/local_playlist_migration_test.dart`
- `app/test/datastore/media_history_settings_test.dart`
- `app/test/datastore/preferences_data_source_test.dart`
- `app/test/domain/get_recent_search_queries_use_case_test.dart`
- `app/test/domain/get_search_contents_use_case_test.dart`
- `app/test/feature/home/home_config_test.dart`
- `app/test/feature/media_library/media_history_cubit_test.dart`
- `app/test/feature/search_state_test.dart`
- `app/test/feature/video/media_stream_bloc_test.dart`
- `app/test/feature/video/player/media_edl_test.dart`
- `app/test/feature/video/player/media_playback_controller_test.dart`
- `app/test/feature/video/player/playback_error_test.dart`
- `app/test/feature/video/probe_test.dart`
- `app/test/feature/video_bloc_test.dart`
- `app/test/layout_breakpoints_test.dart`
- `app/test/providers/media_sources_provider_test.dart`
- `app/test/utils/command_test.dart`
- `app/test/utils/platform_info_test.dart`
- `packages/bilibili/bpi/test/api_interceptor_test.dart`
- `packages/bilibili/bpi/test/api_result_test.dart`
- `packages/bilibili/bpi/test/bangumi_play_url_test.dart`
- `packages/bilibili/bpi/test/bangumi_season_test.dart`
- `packages/bilibili/bpi/test/danmaku_test.dart`
- `packages/bilibili/bpi/test/danmaku_ws/danmaku_message_test.dart`
- `packages/bilibili/bpi/test/danmaku_ws/packet_test.dart`
- `packages/bilibili/bpi/test/from_json_test.dart`
- `packages/bilibili/bpi/test/live_danmaku_test.dart`
- `packages/bilibili/bpi/test/live_room_detail_test.dart`
- `packages/bilibili/bpi/test/live_room_play_info_test.dart`
- `packages/bilibili/bpi/test/player_v2_test.dart`
- `packages/bilibili/bpi/test/popular_feed_test.dart`
- `packages/bilibili/bpi/test/ranking_feed_test.dart`
- `packages/bilibili/bpi/test/reply_pagination_test.dart`
- `packages/bilibili/bpi/test/token_manager_test.dart`
- `packages/bilibili/bpi/test/user_articles_test.dart`
- `packages/bilibili/bpi/test/user_card_test.dart`
- `packages/bilibili/bpi/test/video_data_models_test.dart`
- `packages/bilibili/bpi/test/wbi_utils_test.dart`
- `packages/bilibili/test/bili_live_danmaku_remote_data_source_test.dart`
- `packages/bilibili/test/bili_media_stream_test.dart`
- `packages/bilibili/test/bili_popular_feed_test.dart`
- `packages/bilibili/test/bili_search_remote_data_sources_test.dart`
- `packages/bilibili/test/bili_search_suggest_remote_data_source_test.dart`
- `packages/bilibili/test/bili_url_normalization_test.dart`
- `packages/bilibili/test/bili_video_data_sources_test.dart`
- `packages/bilibili/test/l10n_test.dart`
- `packages/bilibili/test/network/model/network_search_result_test.dart`
- `packages/bilibili/test/network/model/network_search_suggest_test.dart`
- `packages/data/test/danmaku_test.dart`
- `packages/data/test/full_playlist_fetcher_test.dart`
- `packages/data/test/remote_data_source_test.dart`
- `packages/youtube/test/youtube_test.dart`
- `packages/youtube/ypi/test/from_json_test.dart`
- `packages/youtube/ypi/test/youtube_service_test.dart`
- `packages/youtube/ypi/test/yt_protobuf_encoder_test.dart`

## widget（45）

- `app/test/feature/app_search_anchor_test.dart`
- `app/test/feature/filter_bar_test.dart`
- `app/test/feature/history_settings_screen_test.dart`
- `app/test/feature/home/feed_status_view_test.dart`
- `app/test/feature/home/home_config_editor_screen_test.dart`
- `app/test/feature/home/live_feed_section_test.dart`
- `app/test/feature/home_bloc_test.dart`
- `app/test/feature/home_filter_bar_test.dart`
- `app/test/feature/home_source_selector_test.dart`
- `app/test/feature/live/live_screen_test.dart`
- `app/test/feature/media_library/local_library_screen_test.dart`
- `app/test/feature/media_library/media_library_screen_test.dart`
- `app/test/feature/media_library/playlist_picker_test.dart`
- `app/test/feature/not_found_screen_test.dart`
- `app/test/feature/player_settings_screen_test.dart`
- `app/test/feature/search/search_result_screen_test.dart`
- `app/test/feature/search_result_test.dart`
- `app/test/feature/search_screen_test.dart`
- `app/test/feature/setting_screen_test.dart`
- `app/test/feature/space/space_screen_test.dart`
- `app/test/feature/video/playback_speed_chip_test.dart`
- `app/test/feature/video/player_gesture_layer_test.dart`
- `app/test/feature/video/player_keyboard_shortcuts_test.dart`
- `app/test/feature/video/quality_picker_chip_test.dart`
- `app/test/feature/video/sleep_timer_chip_test.dart`
- `app/test/feature/video/video_info_view_chapters_test.dart`
- `app/test/feature/video/video_info_view_queue_test.dart`
- `app/test/feature/video/video_player_placeholder_test.dart`
- `app/test/feature/video/video_player_test.dart`
- `app/test/feature/video/video_screen_test.dart`
- `app/test/feature/video_comments_view_test.dart`
- `app/test/feature/video_error_masking_test.dart`
- `app/test/feature/video_info_view_test.dart`
- `app/test/providers/bloc_providers_test.dart`
- `app/test/providers/repo_providers_test.dart`
- `app/test/providers/service_source_providers_test.dart`
- `app/test/routing/route_data_build_test.dart`
- `app/test/routing/router_resolve_source_test.dart`
- `app/test/routing/router_search_focus_test.dart`
- `app/test/routing/router_settings_test.dart`
- `app/test/ui/app_navigation_shell_test.dart`
- `app/test/ui/app_scroll_behavior_test.dart`
- `app/test/ui/creator_profile_item_test.dart`
- `app/test/ui/video_card_test.dart`
- `packages/bilibili/test/widget_test.dart`

## golden（8）

- `app/test/golden/creator_profile_item_golden_test.dart`
- `app/test/golden/dark_theme_golden_test.dart`
- `app/test/golden/filter_bar_golden_test.dart`
- `app/test/golden/home_screen_golden_test.dart`
- `app/test/golden/not_found_screen_golden_test.dart`
- `app/test/golden/video_card_golden_test.dart`
- `app/test/golden/video_feed_section_golden_test.dart`
- `app/test/golden/video_info_view_golden_test.dart`

## contract（12）

- `app/test/golden/golden_font_contract_test.dart`
- `app/test/golden/hardcoded_copy_test.dart`
- `app/test/design/app_style_test.dart`
- `app/test/design/contrast_test.dart`
- `app/test/design/hardcoded_color_test.dart`
- `app/test/design/palette_test.dart`
- `app/test/design/theme_wrapper_test.dart`
- `app/test/design/token_wiring_test.dart`
- `app/test/routing/router_security_test.dart`
- `app/test/routing/router_structure_test.dart`
- `packages/bilibili/bpi/test/doc_guardrail_test.dart`
- `packages/youtube/ypi/test/doc_guardrail_test.dart`

## integration（2）

- `app/test/main_test.dart`
- `app/test/widget_test.dart`

## performance（0）

当前无文件。新增性能基准测试后在此登记。
