class NewsArticle {
  final String  id;
  final String  title;
  final String  description;
  final String  url;
  final String? imageUrl;
  final String  source;
  final DateTime publishedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get timeAgoRu {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes} мин назад';
    if (diff.inHours   < 24)  return '${diff.inHours} ч назад';
    return '${diff.inDays} дн назад';
  }
}
