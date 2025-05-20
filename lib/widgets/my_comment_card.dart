import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/comment.dart';

class MyCommentCard extends StatelessWidget {
  final Comment comment;
  final String? currentUserId;
  final Function()? onDelete;

  const MyCommentCard({
    super.key,
    required this.comment,
    this.currentUserId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser =
        currentUserId != null && currentUserId == comment.userId;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.isAnonymous
                      ? 'Anonymous'
                      : 'User ${comment.userId.substring(0, 5)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: onDelete,
                    color: Colors.red,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Delete comment',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(comment.content),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('MMM d, yyyy • h:mm a').format(comment.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentInput extends StatefulWidget {
  final Function(String, bool) onSubmit;

  const CommentInput({super.key, required this.onSubmit});

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
              ),
              const Text('Post anonymously'),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    helperText:
                        'Comments are moderated for inappropriate content',
                    helperStyle: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    widget.onSubmit(_controller.text.trim(), _isAnonymous);
                    _controller.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentsList extends StatelessWidget {
  final List<Comment> comments;
  final String? currentUserId;
  final Function(String)? onDeleteComment;

  const CommentsList({
    super.key,
    required this.comments,
    this.currentUserId,
    this.onDeleteComment,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No comments yet'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return MyCommentCard(
          comment: comment,
          currentUserId: currentUserId,
          onDelete: onDeleteComment != null
              ? () => onDeleteComment!(comment.id)
              : null,
        );
      },
    );
  }
}
