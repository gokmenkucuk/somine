# API Categories + Items Migration Step 3

Bu adımda `categories` ve `items` modülleri birlikte API-first hale getirildi.

## Yapılanlar

- `CategoryModel` backend DTO'larından üretilebilir hale getirildi.
- `ItemModel` backend DTO'larından üretilebilir hale getirildi.
- `CategoryRepository` backend auth açıksa `/api/categories` uçlarını kullanıyor.
- `ItemRepository` backend auth açıksa `/api/items` uçlarını kullanıyor.
- Firebase fallback korunuyor. `SOMINE_API_BASE_URL` yoksa eski Firestore akışı devam ediyor.
- Stream tabanlı ekranlar için backend modunda polling kullanılıyor.

## Backend Eşleşmeleri

Kategori işlemleri:

- `GET /api/categories`
- `POST /api/categories`
- `PUT /api/categories/{id}`
- `DELETE /api/categories/{id}`
- `PATCH /api/categories/reorder`

İçerik işlemleri:

- `GET /api/items`
- `GET /api/items/{id}`
- `POST /api/items`
- `PUT /api/items/{id}`
- `DELETE /api/items/{id}`
- `POST /api/items/batch-move`
- `POST /api/items/batch-delete`
- `PATCH /api/items/batch-reorder`
- `GET /api/items/favorites`
- `GET /api/items/search`
- `GET /api/items/deleted`
- `POST /api/items/{id}/restore`
- `DELETE /api/items/{id}/permanent`
- `POST /api/items/copy`

## Davranış Notları

- Kategoriler ve item'lar birlikte taşındı çünkü backend category id'leri ile Firestore category id'leri farklı.
- `streamCategories`, `streamItems` ve `streamRecentItems` backend modunda 2 saniyelik polling kullanıyor.
- `moveToCategory(itemId, null)` için backend tarafında `clearCategory` desteği eklendi.
- `getItemsPaginated` backend modunda desteklenmiyor. Mevcut provider zinciri buna bağımlı değil.
- `copyItemsToCollection` backend modunda yalnızca hedef kullanıcı mevcut oturum kullanıcısıysa API üzerinden çalışıyor.
- `deleteAllUserItems` backend modunda toplu endpoint olmadığı için tek tek permanent delete yapıyor.

## Doğrulama

- `flutter analyze --no-pub lib/core/repositories/item_repository.dart lib/core/repositories/category_repository.dart lib/core/models/item_model.dart lib/core/models/category_model.dart lib/core/providers/firestore_providers.dart`
- Sonuç: hata yok

## Sonraki Adım

Bir sonraki mantıklı modül:

- reminders
- notifications
- shares

Bu üçü item/category id alanlarına bağlı olduğu için artık API geçişine uygun zeminde.
