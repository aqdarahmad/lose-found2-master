import 'package:flutter/material.dart';
import '../api.dart';
import 'post_card.dart';

class PostsList extends StatelessWidget {
  const PostsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PostFeed(loader: () => Api.posts());
  }
}
