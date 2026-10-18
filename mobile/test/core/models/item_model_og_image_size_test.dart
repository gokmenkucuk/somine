import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/models/item_model.dart';

/// Sunucuda saklanan og:image boyutu, masonry kutusunun oranını her cihazda
/// ilk karede bilmek için kullanılıyor. Buradaki testler boyutun API'den
/// güvenli okunmasını, geri gönderilmesini ve yanlış görsele uygulanmamasını
/// koruyor.
Map<String, dynamic> _apiItem({
  Object? width,
  Object? height,
  String? url = 'https://example.com/post',
  String? ogImageUrl = 'https://cdn.example.com/cover.jpg',
}) {
  return <String, dynamic>{
    'id': 'item-1',
    'type': 'link',
    'url': url,
    'ogImageUrl': ogImageUrl,
    if (width != null) 'ogImageWidth': width,
    if (height != null) 'ogImageHeight': height,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
  };
}

void main() {
  group('ItemModel og:image boyutu', () {
    test('API boyutu okunur ve oran hesaplanır', () {
      final item = ItemModel.fromApi(
        _apiItem(width: 1600, height: 900),
        userId: 'user-1',
      );

      expect(item.ogImageWidth, 1600);
      expect(item.ogImageHeight, 900);
      expect(item.serverImageAspectRatio, closeTo(16 / 9, 0.0001));
    });

    test('boyut göndermeyen eski kayıtlarda null kalır', () {
      final item = ItemModel.fromApi(_apiItem(), userId: 'user-1');

      expect(item.ogImageWidth, isNull);
      expect(item.ogImageHeight, isNull);
      // Yerel önbelleğe/varsayılana düşülmesi için null dönmeli.
      expect(item.serverImageAspectRatio, isNull);
    });

    test('bozuk boyutlar (0, negatif) null sayılır', () {
      final zero = ItemModel.fromApi(
        _apiItem(width: 0, height: 0),
        userId: 'user-1',
      );
      final negative = ItemModel.fromApi(
        _apiItem(width: -1600, height: 900),
        userId: 'user-1',
      );

      expect(zero.serverImageAspectRatio, isNull);
      expect(negative.serverImageAspectRatio, isNull);
    });

    test('gösterilen görsel og:image değilse oran kullanılmaz', () {
      // Harita bağlantılarında ContentPreviewPolicy og:image'i eler; kutuya
      // başka bir görselin oranı uygulanmamalı.
      final mapItem = ItemModel.fromApi(
        _apiItem(
          width: 1600,
          height: 900,
          url: 'https://maps.google.com/?q=41,29',
        ),
        userId: 'user-1',
      );

      expect(mapItem.ogImageWidth, 1600);
      expect(mapItem.serverImageAspectRatio, isNull);
    });

    test('boyut create ve update isteklerinde gönderilir', () {
      final item = ItemModel.fromApi(
        _apiItem(width: 1200, height: 1500),
        userId: 'user-1',
      );

      expect(item.toApiCreateRequest()['ogImageWidth'], 1200);
      expect(item.toApiCreateRequest()['ogImageHeight'], 1500);
      expect(item.toApiUpdateRequest()['ogImageWidth'], 1200);
      expect(item.toApiUpdateRequest()['ogImageHeight'], 1500);
    });

    test('copyWith boyutu taşır ve günceller', () {
      final item = ItemModel.fromApi(
        _apiItem(width: 1200, height: 1500),
        userId: 'user-1',
      );

      expect(item.copyWith(note: 'x').ogImageWidth, 1200);
      expect(item.copyWith(ogImageWidth: 800).ogImageWidth, 800);
      expect(item.copyWith(ogImageWidth: 800).ogImageHeight, 1500);
    });
  });
}
