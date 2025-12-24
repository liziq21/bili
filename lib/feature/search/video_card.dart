import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/search/video_search_result.dart';
import '../../../utils/image_error_listener.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({
    super.key,
    required this.duration,
    required this.pic,
    required this.play,
    required this.senddate,
    this.onTap,
  });

  final String duration;
  final String pic;
  final String play;
  final String senddate;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
        fit: .expand,
        children: [
          ClipRRect(
            borderRadius: .circular(4.0),
            child: Stack(
              alignment: .bottomRight,
              children: [
                /*FittedBox(
                  alignment: .center,
                  fit: BoxFit.cover,
                  child: */CachedNetworkImage(
                    imageUrl: 'https:$pic',
                    alignment: .center,
                    fit: .cover,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    errorListener: imageErrorListener,
                  ),
                //),
                Positioned(
                  bottom: 8.0,
                  right: 8.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7), 
                      borderRadius: .circular(4.0),
                    ),
                    child: Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: .bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 6.0,
            top: 6.0
            bottom: 6.0,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Title(
                  title: Text(
                    videoInfo.title,
                    maxLines: 2,
                    overflow: .fade,
                  )
                ),
                Spacer(),
                Text('$play views • $senddate'),
              ],
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}