import 'package:flutter/material.dart';
import '../api.dart';
import 'post_card.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Posts')),
      body: PostFeed(
        loader: () => Api.savedPosts(),
        emptyText: 'No saved posts yet.',
      ),
    );
  }
}
