import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/data/onboarding_demo_content.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/repositories/onboarding_repository.dart';
import 'package:somine_app/core/repositories/user_repository.dart';
import 'package:somine_app/core/services/metadata_service.dart';
import 'package:somine_app/core/utils/app_l10n.dart';

/// İlerleme bildirimi (0.0–1.0).
typedef OnboardingPrepProgress = void Function(double progress);

/// Yeni kullanıcının örnek içeriğini hazırlayan iş.
///
/// Ekrandan bağımsızdır: `BuildContext`'e ya da widget durumuna dokunmaz, bu
/// yüzden kullanıcı ekrandan erken ayrılsa da sonuna kadar çalışır. Hata
/// durumunda istisna fırlatır; çağıran taraf "yine de tamamla" davranışını
/// kendisi uygular.
typedef OnboardingContentPreparer =
    Future<void> Function({
      required String userId,
      String? displayName,
      required OnboardingPrepProgress onProgress,
    });

/// Testlerde sahte bir hazırlık işiyle değiştirilebilsin diye provider.
final onboardingContentPreparerProvider = Provider<OnboardingContentPreparer>(
  (ref) => prepareOnboardingContent,
);

/// Profil adı + varsayılan kategoriler + örnek içerikler.
Future<void> prepareOnboardingContent({
  required String userId,
  String? displayName,
  required OnboardingPrepProgress onProgress,
}) async {
  final userRepository = UserRepository();
  final categoryRepository = CategoryRepository();
  final itemRepository = ItemRepository();

  // Örnek içerik listesi önce API'den istenir (uygulama sürümü
  // yayınlamadan güncellenebilsin); alınamazsa sabit listeye düşülür.
  final demoItems = await OnboardingRepository().loadDemoItems();

  // Profil + kategoriler + her örnek içerik için birer adım.
  final totalSteps = 2 + demoItems.length;
  int currentStep = 0;

  void incrementStep() {
    currentStep++;
    onProgress((currentStep / totalSteps).clamp(0.0, 1.0));
  }

  // 1. Update user name (Step 1)
  if (displayName != null && displayName.isNotEmpty) {
    await userRepository.updateUserProfile(
      uid: userId,
      displayName: displayName,
    );
  }
  incrementStep();

  // 2. Create default categories (Step 2)
  // Adlar veri olarak saklanıyor; kullanıcının dilinde oluşturuluyor.
  // Context yerine appL10n kullanılıyor: bu akış birden çok await sonrası
  // devam ediyor (ve ekran kapandıktan sonra da sürebiliyor), context'e async
  // boşluktan sonra dokunmak istemiyoruz.
  final l10n = appL10n;
  final categories = await categoryRepository.createDefaultCategories(
    userId,
    musicName: l10n.defaultCategoryMusic,
    placesName: l10n.defaultCategoryPlaces,
    restaurantsName: l10n.defaultCategoryRestaurants,
    inspirationName: l10n.defaultCategoryInspiration,
  );
  incrementStep();

  // 3. Find categories for demo content
  //
  // Eşleştirme, oluştururken GÖNDERDİĞİMİZ adla yapılıyor. `order` alanına
  // bakılamaz: sunucu her yeni kategoriyi `SortOrder = 0` ile yaratıp
  // diğerlerini bir kaydırıyor (CategoriesController), dolayısıyla dönen
  // dört DTO'nun da order'ı 0 — order'a bakmak hepsini ilk kategoriye
  // toplardı. Ada bakmak dilden bağımsız çalışır, çünkü karşılaştırılan
  // dize de aynı l10n'dan geliyor.
  CategoryModel categoryByName(String name) => categories.firstWhere(
    (c) => c.name == name,
    orElse: () => categories.first,
  );

  // Dilden bağımsız koleksiyon anahtarı -> oluşturulan kategori.
  final categoryIdByKey = {
    DemoCollection.music: categoryByName(l10n.defaultCategoryMusic).id,
    DemoCollection.places: categoryByName(l10n.defaultCategoryPlaces).id,
    DemoCollection.restaurants:
        categoryByName(l10n.defaultCategoryRestaurants).id,
    DemoCollection.recipes: categoryByName(l10n.defaultCategoryRestaurants).id,
    DemoCollection.inspiration:
        categoryByName(l10n.defaultCategoryInspiration).id,
  };

  if (kDebugMode) {
    debugPrint(
      '[Onboarding] categories=${categories.map((c) => c.name).toList()} '
      'demoItems=${demoItems.length}',
    );
  }

  // 4. Create demo content (one step per item)
  // Liste: API (GET /api/onboarding/demo-content), yedeği
  // lib/core/data/onboarding_demo_content.dart
  //
  // Önizlemeler hepsi birden paralel çekiliyor (16 sıralı istek ~15 sn
  // sürüyordu); öğeler yine liste sırasıyla kaydediliyor ki tarih
  // sıralaması ve ilerleme çubuğu bozulmasın.
  final metadataFutures = [
    for (final demo in demoItems)
      MetadataService.fetchMetadata(demo.url).catchError((Object _) => null),
  ];

  final now = DateTime.now();
  int hourOffset = 0;

  for (var i = 0; i < demoItems.length; i++) {
    final demo = demoItems[i];
    try {
      final url = demo.url;
      final categoryId =
          categoryIdByKey[demo.collection] ?? categories.first.id;

      final metadata = await metadataFutures[i];

      final item = ItemModel(
        id: '',
        userId: userId,
        categoryId: categoryId,
        type: ItemType.link,
        url: url,
        ogMetadata: metadata,
        createdAt: now.subtract(Duration(hours: hourOffset)),
        updatedAt: now.subtract(Duration(hours: hourOffset)),
      );

      await itemRepository.createItem(item);
      hourOffset++;
    } catch (e) {
      debugPrint('⚠️ [Onboarding] Error creating demo item: $e');
    } finally {
      incrementStep();
    }
  }
}
