import 'package:FullVendor/generated/assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FullVendorCacheImageLoader extends StatefulWidget {
  const FullVendorCacheImageLoader({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.fit,
  });
  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;

  @override
  State<FullVendorCacheImageLoader> createState() => _FullVendorCacheImageLoaderState();
}

class _FullVendorCacheImageLoaderState extends State<FullVendorCacheImageLoader> {
  // int retryCount = 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(tr('image')),
              content: CachedNetworkImage(
                imageUrl: widget.imageUrl ?? 'https://example.com',
                cacheKey: widget.imageUrl ?? 'https://example.com',
                fit: widget.fit,
                errorWidget: (context, url, error) {
                  return Container(
                    constraints: const BoxConstraints(minHeight: 200, minWidth: 200),
                    alignment: Alignment.center,
                    child: const Icon(Icons.error),
                  );
                },
                placeholder: (context, url) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(tr('close')),
                ),
              ],
            );
          },
        );
      },
      child: CachedNetworkImage(
        // key: ValueKey(retryCount),
        imageUrl: widget.imageUrl ?? 'https://example.com',
        cacheKey: widget.imageUrl ?? 'https://example.com',
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        errorWidget: (context, url, error) {
          return Container(alignment: Alignment.center, child: Image.asset(Assets.imagesNoImage));
        },
      ),
    );
  }
}
