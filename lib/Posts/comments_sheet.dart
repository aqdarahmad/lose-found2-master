import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';

// showCommentsSheet(context, postId);
void showCommentsSheet(BuildContext context, String postId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => CommentsSheet(postId: postId),
  );
}

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final c = await Api.comments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _addComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    try {
      await Api.addComment(widget.postId, text);
      _ctrl.clear();
      if (!mounted) return;
      setState(() => _loading = true);
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            SizedBox(
              height: 300,
              child: _comments.isEmpty
                  ? const Center(child: Text('No comments yet.'))
                  : ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (ctx, i) {
                        final c = _comments[i];
                        final user = Map<String, dynamic>.from(c['author'] as Map);
                        return ListTile(
                          leading: AvatarImage(
                            url: (user['avatarURL'] as String?) ?? '',
                            radius: 20,
                          ),
                          title: Text(
                            '${user['username']} • ${formatTimeAgo(c['createdAt'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            c['text'] as String,
                            style: const TextStyle(fontSize: 17),
                          ),
                        );
                      },
                    ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width : MediaQuery.of(context).size.width - 80,

                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(labelText: 'Write a comment…'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
