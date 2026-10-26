import 'package:flutter/material.dart';
import '../api.dart';
import 'comments_sheet.dart';

class PostActions extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostActions({Key? key, required this.post}) : super(key: key);

  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions> {
  late int likeCount;
  late bool isLiked;
  late bool isResolved;

  String get _postId => widget.post['id'].toString();

  @override
  void initState() {
    super.initState();
    likeCount = (widget.post['likeCount'] as int?) ?? 0;
    isLiked = (widget.post['liked'] as bool?) ?? false;
    isResolved = (widget.post['isResolved'] as bool?) ?? false;
  }

  Future<void> _toggleLike() async {
    final wasLiked = isLiked;
    final oldCount = likeCount;
    // optimistic update
    setState(() {
      isLiked = !wasLiked;
      likeCount = wasLiked ? oldCount - 1 : oldCount + 1;
    });
    try {
      final p = await Api.setLike(_postId, !wasLiked);
      if (!mounted) return;
      setState(() {
        likeCount = (p['likeCount'] as int?) ?? likeCount;
        isLiked = (p['liked'] as bool?) ?? isLiked;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLiked = wasLiked;
        likeCount = oldCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isResolved ? Icons.check_circle : Icons.error_outline,
          color: isResolved ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          isResolved ? 'Founded' : 'Lose',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.black,
          ),
          onPressed: _toggleLike,
        ),
        Text('$likeCount'),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.mode_comment_outlined),
          onPressed: () => showCommentsSheet(context, _postId),
        ),
        SavePostButton(
          postId: _postId,
          initialSaved: (widget.post['saved'] as bool?) ?? false,
        ),
      ],
    );
  }
}

class SavePostButton extends StatefulWidget {
  final String postId;
  final bool initialSaved;

  const SavePostButton({Key? key, required this.postId, this.initialSaved = false})
      : super(key: key);

  @override
  State<SavePostButton> createState() => _SavePostButtonState();
}

class _SavePostButtonState extends State<SavePostButton> {
  late bool isSaved = widget.initialSaved;

  Future<void> _toggleSave() async {
    final was = isSaved;
    setState(() => isSaved = !was);
    try {
      await Api.setSaved(widget.postId, !was);
      Api.notifyPostsChanged(); // refresh the "Saved posts" list
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaved = was);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: isSaved ? Colors.orange : Colors.black,
      ),
      onPressed: _toggleSave,
    );
  }
}
