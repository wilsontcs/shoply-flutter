import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Uri? uri = Uri.tryParse(url);
    final Widget fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 36),
      ),
    );
    return Semantics(
      image: true,
      label: label,
      child: AspectRatio(
        aspectRatio: 1,
        child: ExcludeSemantics(
          child:
              uri == null ||
                  !<String>{'https', 'http'}.contains(uri.scheme) ||
                  uri.host.isEmpty
              ? fallback
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (BuildContext context, String url) => ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget:
                      (BuildContext context, String url, Object error) =>
                          fallback,
                ),
        ),
      ),
    );
  }
}
