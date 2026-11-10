import 'package:flutter/material.dart';

import 'package:shoply_flutter/constants/dimensions.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Loading products'});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Dimensions.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(semanticsLabel: label),
          const SizedBox(height: Dimensions.spacing * 2),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
