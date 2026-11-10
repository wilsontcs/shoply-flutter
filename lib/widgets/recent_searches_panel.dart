import 'package:flutter/material.dart';
import 'package:shoply_flutter/controllers/recent_searches_controller.dart';

class RecentSearchesPanel extends StatelessWidget {
  const RecentSearchesPanel({
    super.key,
    required this.controller,
    required this.onSelect,
  });

  final RecentSearchesController controller;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Recent searches',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: controller.queries.isEmpty
                  ? null
                  : controller.clearAsync,
              child: const Text('Clear all'),
            ),
          ],
        ),
        if (controller.isLoading)
          const LinearProgressIndicator(
            semanticsLabel: 'Loading recent searches',
          )
        else if (controller.queries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Your recent searches will appear here.'),
          )
        else
          for (final String query in controller.queries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.history),
              title: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.north_west, size: 18),
              onTap: () => onSelect(query),
            ),
        if (controller.error != null)
          Row(
            children: <Widget>[
              Expanded(child: Text(controller.error!)),
              TextButton(
                onPressed: controller.retryAsync,
                child: const Text('Retry'),
              ),
            ],
          ),
        const Divider(),
      ],
    );
  }
}
