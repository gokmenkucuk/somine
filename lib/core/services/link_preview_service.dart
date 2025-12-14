import 'package:somine_app/core/models/link_preview_model.dart';

class LinkPreviewService {
  Future<LinkPreviewModel> fetchPreview(String url) async {
    // For now, return mock data to demonstrate the UI
    // In a real app, this would use Cloud Functions or a local scraper
    // But local scraping has CORS issues on web and sometimes policy issues on mobile
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return LinkPreviewModel(
        url: url,
        title: 'Rick Astley - Never Gonna Give You Up (Official Music Video)',
        description: 'The official video for "Never Gonna Give You Up" by Rick Astley',
        imageUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        siteName: 'YouTube',
      );
    }

    if (url.contains('medium.com')) {
      return LinkPreviewModel(
        url: url,
        title: 'Understanding Flutter’s Rendering Pipeline',
        description: 'A deep dive into how Flutter renders widgets to the screen.',
        imageUrl: 'https://miro.medium.com/v2/resize:fit:1200/1*5-pwoz7jbbDO7aJk-G9jDw.png',
        siteName: 'Medium',
      );
    }

    // Default mock for other URLs
    return LinkPreviewModel(
      url: url,
      title: 'Example Page Title',
      description: 'This is a description of the shared link.',
      imageUrl: 'https://via.placeholder.com/300x200',
      siteName: 'Website',
    );
  }
}
