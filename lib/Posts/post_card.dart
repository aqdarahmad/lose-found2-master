import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';
import 'post_actions.dart';

/// One post (header, text, image, like/comment/save actions).
class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final Widget? trailing;
  const PostCard({Key? key, required this.post, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final author = Map<String, dynamic>.from(post['author'] as Map);
    final description = (post['description'] as String?) ?? '';
    final imageURL = (post['imageURL'] as String?) ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarImage(url: (author['avatarURL'] as String?) ?? '', radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (author['username'] as String?) ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatTimeAgo(post['createdAt']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            if (imageURL.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: netImage(imageURL, height: 300),
                ),
              ),
            ],
            const SizedBox(height: 8),
            PostActions(key: ValueKey(post['id']), post: post),
          ],
        ),
      ),
    );
  }
}

/// A list of posts loaded from the server. Reloads when [Api.postsChanged]
/// fires and supports pull-to-refresh (unless [shrink] is used inside a
/// parent scroll view).
class PostFeed extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() loader;
  final Widget Function(Map<String, dynamic> post)? trailingBuilder;
  final bool shrink;
  final String emptyText;

  const PostFeed({
    Key? key,
    required this.loader,
    this.trailingBuilder,
    this.shrink = false,
    this.emptyText = 'No posts yet.',
  }) : super(key: key);

  @override
  State<PostFeed> createState() => _PostFeedState();
}

class _PostFeedState extends State<PostFeed> {
  List<Map<String, dynamic>>? _posts;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Api.postsChanged.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    Api.postsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await widget.loader();
      if (!mounted) return;
      setState(() {
        _posts = p;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
      );
    }
    if (_posts == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Error loading posts'),
              TextButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final posts = _posts!;
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(widget.emptyText, style: const TextStyle(color: Colors.black)),
        ),
      );
    }
    final cards = posts
        .map((p) => PostCard(
              key: ValueKey(p['id']),
              post: p,
              trailing: widget.trailingBuilder?.call(p),
            ))
        .toList();
    if (widget.shrink) return Column(children: cards);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        children: cards,
      ),
    );
  }
}
