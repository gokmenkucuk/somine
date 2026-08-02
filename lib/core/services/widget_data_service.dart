import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/item_repository.dart';

/// iOS ana ekran widget'ı ("günün kaydı") veri köprüsü.
///
/// "Günün kaydı"nı seçer, App Group UserDefaults'a yazar
/// (`ios/SomineWidget/SomineWidget.swift` bu anahtarları okur) ve widget
/// timeline'ını yeniler. Seçim tarih-tohumlu deterministiktir: aynı gün hep
/// aynı kayıt, gün değişince farklı kayıt. Hatalar asla dışarı sızmaz —
/// açılış/kayıt akışını bozamaz (debugPrint ile yutulur).
class WidgetDataService {
  static final WidgetDataService _instance = WidgetDataService._internal();
  factory WidgetDataService() => _instance;
  WidgetDataService._internal();

  /// Runner + share extension'da zaten tanımlı App Group.
  static const String appGroupId = 'group.com.somine.app';

  /// Widget kind/target adı (SomineWidget.swift `kind` ile aynı olmalı).
  static const String iOSWidgetName = 'SomineWidget';

  /// Deterministik gün sayacı için sabit çapa tarihi.
  static final DateTime _epoch = DateTime(2020, 1, 1);

  final ItemRepository _itemRepository = ItemRepository();

  /// App açılışında çağrılır (main.dart, WeeklyDigestService.syncOnAppStart
  /// yanı — aynı kalıp: unawaited, hatalar içeride yutulur).
  Future<void> syncOnAppStart(String userId) => sync(userId);

  /// "Günün kaydı"nı seçip widget verisini günceller.
  /// Tetikler: app açılışı + yeni kayıt (add_content kayıt başarısı).
  Future<void> sync(String userId) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      final items = await _itemRepository.getItems(userId);
      final active = items.where((item) => !item.isDeleted).toList();
      final selected = _selectItemOfTheDay(active);

      if (selected == null) {
        // Kayıt yok — widget boş-durum gösterir.
        await HomeWidget.saveWidgetData<String?>('widget_title', null);
        await HomeWidget.saveWidgetData<String?>('widget_type', null);
        await HomeWidget.saveWidgetData<String?>('widget_domain', null);
        await HomeWidget.saveWidgetData<String?>('widget_item_id', null);
      } else {
        await HomeWidget.saveWidgetData<String>(
          'widget_title',
          selected.displayTitle,
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_type',
          selected.type.name,
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_domain',
          _domainOf(selected),
        );
        await HomeWidget.saveWidgetData<String>('widget_item_id', selected.id);
      }

      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
      debugPrint(
        'ℹ️ [WidgetData] Widget synced: ${selected?.id ?? '(empty)'}',
      );
    } catch (e) {
      debugPrint('❌ [WidgetData] sync error (ignored): $e');
    }
  }

  /// "Günün kaydı" seçimi:
  /// 1. Hiç açılmamış (`lastOpenedAt == null`) kayıtlardan tarih-tohumlu
  ///    deterministik seçim (gün değişince değişir),
  /// 2. Fallback: favoriler (aynı deterministik seçim),
  /// 3. Fallback: en eski kayıt.
  ItemModel? _selectItemOfTheDay(List<ItemModel> items) {
    if (items.isEmpty) return null;

    var candidates = items.where((item) => item.lastOpenedAt == null).toList();
    if (candidates.isEmpty) {
      candidates = items.where((item) => item.isFavorite).toList();
    }
    if (candidates.isEmpty) {
      final oldestFirst = [...items]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return oldestFirst.first;
    }

    // Deterministik: sabit sıraya (id) diz, gün sayısına göre index seç.
    candidates.sort((a, b) => a.id.compareTo(b.id));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayNumber = today.difference(_epoch).inDays;
    return candidates[dayNumber % candidates.length];
  }

  /// Link kayıtlarında url host'u (örn. "youtube.com"); yoksa boş string.
  String _domainOf(ItemModel item) {
    final url = item.url;
    if (url == null || url.isEmpty) return '';
    return Uri.tryParse(url)?.host ?? '';
  }
}
