import 'package:flutter/material.dart';

String formatTimeAgo(dynamic value) {
  final date = value is DateTime
      ? value
      : (DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now());
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
}

/// Network image that also works on Flutter web when the image host does not
/// send CORS headers (falls back to an <img> element).
Widget netImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
}) {
  final fallback = placeholder ??
      Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
  if (url.isEmpty) return fallback;
  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    errorBuilder: (_, __, ___) => fallback,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
  );
}

class AvatarImage extends StatelessWidget {
  final String url;
  final double radius;
  const AvatarImage({Key? key, required this.url, this.radius = 20}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: netImage(
          url,
          width: size,
          height: size,
          placeholder: Container(
            color: Colors.grey[400],
            child: Icon(Icons.person, size: radius, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
