class LinkPreviewModel {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  const LinkPreviewModel({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  bool get hasData => title != null || imageUrl != null;
}
