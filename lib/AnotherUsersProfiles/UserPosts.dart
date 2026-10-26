import 'package:flutter/material.dart';
import '../api.dart';
import '../Posts/post_card.dart';

class UserPosts extends StatelessWidget {
  final String uid;

  const UserPosts({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PostFeed(
      loader: () => Api.posts(authorId: uid),
      shrink: true,
      emptyText: "haven't posted anything yet",
    );
  }
}
