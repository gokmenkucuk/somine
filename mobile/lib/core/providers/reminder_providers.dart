import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/repositories/reminder_repository.dart';

/// ReminderRepository provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

/// Bir hatırlatıcı ve bağlı olduğu içerik. İçerik silinmişse [item] null olur
/// (yetim hatırlatıcı) — liste yine de göstermeli ki kullanıcı silebilsin.
class ReminderWithItem {
  final ReminderModel reminder;
  final ItemModel? item;

  const ReminderWithItem({required this.reminder, this.item});

  /// Sıralama ve yaklaşan/geçmiş ayrımının tek doğru kaynağı.
  /// Ham `reminderDate` tekrarlı hatırlatıcılarda yanlış sonuç verir.
  DateTime get nextOccurrence => reminder.calculateNextOccurrence();

  bool get isPast => nextOccurrence.isBefore(DateTime.now());
}

/// Kullanıcının tüm hatırlatıcıları, içerikleriyle eşleştirilmiş.
///
/// `ReminderRepository.streamUserReminders` 10 sn'de bir poll ettiği için
/// kullanılmıyor; bu ekran çekme-yenile + invalidate ile tazeleniyor.
final remindersWithItemsProvider =
    FutureProvider.autoDispose<List<ReminderWithItem>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return const [];

  final isVaultUnlocked = ref.watch(isVaultUnlockedProvider);

  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final reminders = await reminderRepo.getUserReminders(user.uid);
  if (reminders.isEmpty) return const [];

  // Tek tek getItem() çağırmak 1+N istek eder (her biri token doğrulamasıyla).
  // Tümünü bir kez çekip eşleştirmek N'den bağımsız maliyet demek.
  //
  // Vault içerikleri yalnızca kasa kilidi açıkken çekilir. Kilitliyken bir vault
  // item'ının hatırlatıcısı "içerik bulunamadı" olarak görünür (yetim hatırlatıcı
  // ile aynı zarif düşüş) — kasa başlığının kilitli ekrana sızmaması bilinçli tercih.
  final items = await ItemRepository().getItems(
    user.uid,
    includeVault: isVaultUnlocked,
  );
  final byId = <String, ItemModel>{for (final item in items) item.id: item};

  final result = reminders
      .map((r) => ReminderWithItem(reminder: r, item: byId[r.itemId]))
      .toList();

  result.sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));
  return result;
});
