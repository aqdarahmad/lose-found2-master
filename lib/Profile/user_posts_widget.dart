import 'package:flutter/material.dart';
import '../api.dart';
import '../Posts/post_card.dart';
import 'edit_post.dart';

/// The signed-in user's own posts (with an edit button on each post).
class UserPostsWidget extends StatelessWidget {
  const UserPostsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PostFeed(
      loader: () => Api.posts(authorId: Api.myId),
      shrink: true,
      emptyText: 'No posts yet.',
      trailingBuilder: (post) => IconButton(
        icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPostScreen(
                docId: post['id'].toString(),
                initial: post,
              ),
            ),
          );
          Api.notifyPostsChanged();
        },
      ),
    );
  }
}
