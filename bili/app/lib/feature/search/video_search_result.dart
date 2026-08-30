// import 'package:flutter/material.dart';
// import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
//
// import 'package:data/data.dart';
// import '../../ui/video_card.dart';
// import 'search_result_view_model.dart';
//
// class VideoSearchResult extends StatelessWidget {
//   const VideoSearchResult({super.key, required this.viewModel});
//
//   final SearchResultViewModel<VideoInfoBase> viewModel;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           PagedSliverList<int, VideoInfoBase>(
//             state: viewModel.state,
//             fetchNextPage: viewModel.fetchNextPage,
//             builderDelegate: PagedChildBuilderDelegate(
//               itemBuilder: (_, videoInfoBase, _) => VideoCard(
//                 videoInfoBase: videoInfoBase,
//                 //onTap,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
