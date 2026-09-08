import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:data/data.dart';

class CreatorProfileItem extends StatelessWidget {
  const CreatorProfileItem({
    super.key,
    required this.creatorProfile,
    this.onTap,
  });

  final CreatorProfile creatorProfile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: creatorProfile.thumbnailUrl != null &&
                        creatorProfile.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(creatorProfile.thumbnailUrl!)
                    : null,
                child: creatorProfile.thumbnailUrl == null ||
                        creatorProfile.thumbnailUrl!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorProfile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${creatorProfile.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
