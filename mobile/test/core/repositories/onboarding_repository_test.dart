import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/data/onboarding_demo_content.dart';
import 'package:somine_app/core/repositories/onboarding_repository.dart';

void main() {
  test('parseDemoItems keeps known collections and http(s) links only', () {
    const body = '''
      { "version": "x", "items": [
        { "collection": "places", "url": "https://example.com/a" },
        { "collection": "unknown", "url": "https://example.com/b" },
        { "collection": "music", "url": "javascript:alert(1)" },
        { "collection": "recipes", "url": "http://example.com/c", "note": "n" },
        { "collection": "music" }
      ] }''';

    final items = OnboardingRepository.parseDemoItems(body);

    expect(items.map((i) => i.url), ['https://example.com/a', 'http://example.com/c']);
    expect(items.first.collection, DemoCollection.places);
  });

  test('parseDemoItems returns empty for unexpected shapes', () {
    expect(OnboardingRepository.parseDemoItems('[]'), isEmpty);
    expect(OnboardingRepository.parseDemoItems('{"items": "nope"}'), isEmpty);
  });

  test('bundled fallback list covers all four collections', () {
    final keys = onboardingDemoItems.map((i) => i.collection).toSet();
    expect(keys, {
      DemoCollection.music,
      DemoCollection.places,
      DemoCollection.restaurants,
      DemoCollection.inspiration,
    });
  });
}
