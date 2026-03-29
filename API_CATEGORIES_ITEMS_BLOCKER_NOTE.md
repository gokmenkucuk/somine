# Categories + Items Blocker Note

`categories` modülü tek başına API'ye geçirilemez.

## Sebep

Mobil uygulamadaki item kayıtları şu anda hala Firestore `categoryId` değerlerini kullanıyor.

Backend tarafında ise migration sırasında kategori kayıtları yeni deterministic GUID id'lerle oluşturuldu.

Yani:

- Firestore item `categoryId`
- backend category `id`

şu anda aynı değer değil.

## Risk

Eğer yalnızca `categoriesProvider` API'den beslenirse:

- item'ların kategori eşleşmesi bozulur
- filtreleme yanlış çalışır
- kategori chip'leri ile içerik ilişkisi kopar
- kategori bazlı ekranlar tutarsız hale gelir

## Doğru sonraki adım

`categories` ve `items` modülleri birlikte taşınmalı.

Yani sıradaki teknik paket:

1. `ItemRepository` için API-first katman kurmak
2. `CategoryRepository` ile aynı anda backend id'lerini kullanmak
3. item + category provider'larını birlikte API'ye çevirmek

Bu yüzden auth ve users sonrası doğru veri geçiş paketi:

- `categories + items` together
