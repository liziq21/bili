import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';

class const CreatorProfileItem({
  super.key,
  required final CreatorProfile creatorProfile,
  final Function()? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: .transparency,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const SizedBox(width: 15),
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                creatorProfile.thumbnailUrl,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: .max,
                crossAxisAlignment: .start,
                mainAxisAlignment: .center,
                children: [
                  Text(
                    creatorProfile.name,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('${creatorProfile.id}  Live：${creatorProfile.isLive}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview()
Widget previewCreatorProfileItem() {
  return CreatorProfileItem(
    creatorProfile: .new(
      id: 12234553,
      name: 'name',
      thumbnailUrl: 'https://i0.hdslb.com/bfs/face/9327344f6bbcd32bdd940dad3418df2f77223605.jpg',
      isLive: true,
      roomId: 320032,
    ),
  );
}
