import 'package:flutter/material.dart';

import '../widgets/empty_state_view.dart';

/// Foundation only: catalogue fetching, scrolling and refresh belong to Part 2.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Shoply')),
    body: const CustomScrollView(
      key: PageStorageKey<String>('catalogue-scroll'),
      physics: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            icon: Icons.storefront_outlined,
            title: 'A little discovery awaits',
            message: 'Your products will appear here.',
          ),
        ),
      ],
    ),
  );
}
