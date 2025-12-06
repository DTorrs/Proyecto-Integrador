import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/api_config.dart';
import '../../config/app_theme.dart';

enum ItemType { problem, lostItem }

class ItemCard extends StatelessWidget {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String location;
  final String status;
  final int statusId;
  final DateTime createdAt;
  final String username;
  final ItemType type;
  final int? voteCount;
  final bool? userVoted;
  final VoidCallback onTap;
  final VoidCallback? onVote;
  final bool isFound; // Only for lost items

  const ItemCard({
    Key? key,
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.location,
    required this.status,
    required this.statusId,
    required this.createdAt,
    required this.username,
    required this.type,
    required this.onTap,
    this.voteCount,
    this.userVoted,
    this.onVote,
    this.isFound = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Image.network(
                    '${ApiConfig.uploadBaseUrl}/${type == ItemType.problem ? 'problems' : 'lostitems'}/$imageUrl',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.broken_image, size: 50),
                      );
                    },
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusBadge(),
                      SizedBox(width: 8),
                      if (type == ItemType.lostItem)
                        _buildFoundOrLostBadge(),
                      Spacer(),
                      Text(
                        timeago.format(createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (description != null) ...[
                    Text(
                      description!,
                      style: TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        username,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      if (type == ItemType.problem && onVote != null) ...[
                        InkWell(
                          onTap: onVote,
                          child: Row(
                            children: [
                              Icon(
                                userVoted ?? false
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                size: 16,
                                color: userVoted ?? false
                                    ? AppTheme.primaryColor
                                    : Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                voteCount?.toString() ?? '0',
                                style: TextStyle(
                                  color: userVoted ?? false
                                      ? AppTheme.primaryColor
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (statusId) {
      case 1: // Pending / Reported
        color = AppTheme.pendingColor;
        break;
      case 2: // In Progress / In D300
        color = AppTheme.inProgressColor;
        break;
      case 3: // Resolved / Claimed
        color = AppTheme.resolvedColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFoundOrLostBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFound ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isFound ? Colors.green : Colors.red,
        ),
      ),
      child: Text(
        isFound ? 'Encontrado' : 'Perdido',
        style: TextStyle(
          color: isFound ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}