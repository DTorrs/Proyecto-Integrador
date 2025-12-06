import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comment {
  final int id;
  final String comment;
  final String username;
  final String fullName;
  final DateTime createdAt;
  final bool isOwner;

  Comment({
    required this.id,
    required this.comment,
    required this.username,
    required this.fullName,
    required this.createdAt,
    this.isOwner = false,
  });
}

class CommentSection extends StatelessWidget {
  final List<Comment> comments;
  final Function(String) onAddComment;
  final Function(int)? onDeleteComment;
  final bool isLoading;

  const CommentSection({
    Key? key,
    required this.comments,
    required this.onAddComment,
    this.onDeleteComment,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commentarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildCommentInput(context),
        SizedBox(height: 16),
        if (isLoading)
          Center(child: CircularProgressIndicator())
        else if (comments.isEmpty)
          Center(
            child: Text(
              'Se el primero en comentar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _buildCommentItem(context, comment);
            },
          ),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    final commentController = TextEditingController();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: 'Agrega un comentario',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            minLines: 1,
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () {
            if (commentController.text.trim().isNotEmpty) {
              onAddComment(commentController.text.trim());
              commentController.clear();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '@${comment.username}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (comment.isOwner) ...[
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Author',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              Spacer(),
              Text(
                timeago.format(comment.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (onDeleteComment != null && comment.isOwner)
                IconButton(
                  icon: Icon(Icons.delete, size: 16),
                  onPressed: () => onDeleteComment!(comment.id),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                  splashRadius: 20,
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(comment.comment),
        ],
      ),
    );
  }
}