// App Store ekran görüntüsü düzeneği.
//
// Gerçek uygulama ekranlarını (HomeScreen ve sekmeleri, ekleme ekranı,
// paylaşım ve başarı sayfaları) kurgusal fixture verisiyle çizer ve her
// karede durup host'taki çekim betiğinin `xcrun simctl io screenshot`
// almasını bekler. Böylece görüntüler simülatörün yerel çözünürlüğünde ve
// override edilmiş durum çubuğuyla (9:41, dolu pil) alınır.
//
// Çalıştırma: marketing/screenshots/scripts/capture.sh
// (flutter drive + test_driver/integration_test.dart).
//
// Protokol: test `SOMINE_SHOT::<locale>-<ad>` satırını yazar; betik çekimi
// yapıp uygulamanın Documents klasörüne `shot_ack_<locale>-<ad>` dosyasını
// koyar; test dosyayı görünce bir sonraki ekrana geçer.
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/navigation_providers.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/services/subscription_service.dart';
import 'package:somine_app/core/utils/image_aspect_ratio_cache.dart';
import 'package:somine_app/screens/add_content_screen.dart';
import 'package:somine_app/screens/catalog_screen.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/screens/search_screen.dart';
import 'package:somine_app/widgets/collection_share_options_sheet.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'screenshots/fake_backend.dart';
import 'screenshots/fake_platform.dart';
import 'screenshots/fixtures.dart';

/// `--dart-define=SHOT_LOCALES=tr` gibi; varsayılan iki dil.
const _locales = String.fromEnvironment('SHOT_LOCALES', defaultValue: 'tr,en');

/// Yalnız belirli kareler: `--dart-define=SHOT_ONLY=01-feed,07-search`.
const _only = String.fromEnvironment('SHOT_ONLY');

/// Host betiği olmadan (ör. hızlı deneme) beklemeden geçmek için.
const _noWait = bool.fromEnvironment('SHOT_NO_WAIT');


class _PremiumSubscriptionNotifier extends StateNotifier<SubscriptionState>
    implements SubscriptionNotifier {
  _PremiumSubscriptionNotifier()
    : super(const SubscriptionState(tier: SubscriptionTier.curator));

  @override
  bool canCreateCollection(int currentCount) => true;
  @override
  bool canAddItem(int totalItemCount) => true;
  @override
  bool canCreateReminder(int activeReminderCount) => true;
  @override
  bool canCreateShare(int activeShareCount) => true;
  @override
  bool shouldWarnItemLimit(int totalItemCount) => false;
  @override
  int remainingItems(int totalItemCount) => 9999;
  @override
  Future<void> refresh() async {}
  @override
  Future<bool> purchase(Package package) async => false;
  @override
  Future<bool> restore() async => false;
}

class _ShotApp extends ConsumerWidget {
  const _ShotApp({required this.locale, required this.navigatorKey});

  final String locale;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'somine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(
        theme == AppThemeEnum.system ? AppThemeEnum.air : theme,
      ),
      themeMode: ThemeMode.light,
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}

class _Harness {
  _Harness(this.tester, this.backend);

  final WidgetTester tester;
  final FixtureBackend backend;
  late ProviderContainer container;
  late GlobalKey<NavigatorState> navigatorKey;
  String locale = 'tr';

  BuildContext get navContext => navigatorKey.currentContext!;

  Future<void> wait(double seconds) =>
      Future<void>.delayed(Duration(milliseconds: (seconds * 1000).round()));

  Future<void> pumpHome(AppThemeEnum theme, {int tab = 0}) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await wait(0.3);

    final themeName = switch (theme) {
      AppThemeEnum.midnight => 'midnight',
      AppThemeEnum.vibe => 'vibe',
      _ => 'air',
    };
    SharedPreferences.setMockInitialValues({'theme_mode': themeName});

    navigatorKey = GlobalKey<NavigatorState>();
    container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(FirebaseAuth.instance.currentUser),
        ),
        subscriptionProvider.overrideWith(
          (ref) => _PremiumSubscriptionNotifier(),
        ),
      ],
    );
    container.read(homeTabIndexProvider.notifier).state = tab;
    container.read(initializedHomeTabsProvider.notifier).state = {0, tab};

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _ShotApp(locale: locale, navigatorKey: navigatorKey),
      ),
    );
    // Akışın kendi giriş animasyonları (FadeIn*) ve görsellerin yüklenmesi.
    await wait(3.5);
  }

  Future<void> shot(String name) async {
    await wait(1.2);
    await signal('SOMINE_SHOT', '$locale-$name');
  }

  /// Host betiğine `<kind>::<id>` yazar ve onay dosyasını bekler.
  Future<void> signal(String kind, String id) async {
    if (_noWait) {
      debugPrint('${kind}_SKIP::$id');
      return;
    }
    final docs = await getApplicationDocumentsDirectory();
    final ack = File('${docs.path}/shot_ack_$id');
    if (ack.existsSync()) ack.deleteSync();
    // ignore: avoid_print
    print('$kind::$id');
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (!ack.existsSync()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('screenshot ack timeout: $id');
      }
      await wait(0.2);
    }
    ack.deleteSync();
  }

  CategoryModel category(String id) {
    final c = fixtureCategories.firstWhere((c) => c.id == id);
    final now = DateTime.now();
    return CategoryModel(
      id: c.id,
      userId: fixtureUid,
      name: locale == 'tr' ? c.tr : c.en,
      icon: c.icon,
      color: c.color,
      isVault: c.isVault,
      createdAt: now,
      updatedAt: now,
    );
  }

  String catName(String id) {
    final c = fixtureCategories.firstWhere((c) => c.id == id);
    return locale == 'tr' ? c.tr : c.en;
  }

  Future<void> tapText(String text, {Type? within}) async {
    final finder =
        within == null
            ? find.text(text)
            : find.descendant(of: find.byType(within), matching: find.text(text));
    if (finder.evaluate().isEmpty) {
      debugPrint('🧪 tapText: "$text" bulunamadı');
      return;
    }
    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pump();
  }

  // ------------------------------------------------------------- Kareler

  Future<void> masonry() async {
    final b = find.byIcon(PhosphorIconsLight.layout);
    if (b.evaluate().isNotEmpty) {
      await tester.tap(b.first, warnIfMissed: false);
      await wait(2.0);
    }
  }

  Future<void> feed() async {
    await pumpHome(AppThemeEnum.air);
    await masonry();
    await shot('01-feed');
  }

  Future<void> add() async {
    await pumpHome(AppThemeEnum.air);
    final slug = locale == 'tr' ? addFlowSlugTr : addFlowSlugEn;
    final host = locale == 'tr' ? 'gezi-notlari' : 'travel-notes';
    unawaited(
      showModalBottomSheet(
        context: navContext,
        isScrollControlled: true,
        useSafeArea: false,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        enableDrag: false,
        builder:
            (_) => AddContentScreen(initialText: 'https://$host.example/$slug'),
      ),
    );
    await wait(3.0);
    await tapText(catName(catKas), within: AddContentScreen);
    await wait(1.0);
    await shot('02-add');
  }

  Future<void> reminder() async {
    await pumpHome(AppThemeEnum.air);
    final l10n = AppLocalizations.of(navContext)!;
    unawaited(
      showModalBottomSheet(
        context: navContext,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        // VoiceOver bayrağı sayfanın 4 sn'de kendiliğinden kapanmasını
        // engeller (sayfanın kendi kuralı); görünümü değiştirmez.
        builder:
            (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(accessibleNavigation: true),
              child: SuccessNotificationSheet(
                title: l10n.commonSuccessBang,
                message: l10n.homeAddSuccessMessage,
                quickReminderItemId: 'item-07',
                quickReminderItemTitle:
                    locale == 'tr' ? addFlowTitleTr : addFlowTitleEn,
              ),
            ),
      ),
    );
    await wait(1.5);
    await shot('03-reminder');
  }

  Future<void> collections() async {
    await pumpHome(AppThemeEnum.air, tab: 2);
    await shot('04-collections-shelf');
    final grid = find.byIcon(PhosphorIconsRegular.squaresFour);
    if (grid.evaluate().isNotEmpty) {
      await tester.tap(grid.first, warnIfMissed: false);
      await wait(2.0);
    }
    await shot('04-collections');
  }

  Future<void> share() async {
    await pumpHome(AppThemeEnum.midnight, tab: 2);
    container.read(selectedCatalogIdProvider.notifier).state = catKas;
    await wait(2.0);
    unawaited(
      CollectionShareOptionsSheet.show(
        navContext,
        category: category(catKas),
        onShareWithPeople: () {},
      ),
    );
    await wait(1.5);
    await shot('05-share');
  }

  Future<void> vault() async {
    backend.vaultFirst = true;
    await pumpHome(AppThemeEnum.vibe, tab: 2);
    container.read(selectedCatalogIdProvider.notifier).state = catVault;
    await wait(2.0);
    await shot('06-vault');
    backend.vaultFirst = false;
  }

  Future<void> search() async {
    SearchScreen.debugHidePlatformSourceChips = true;
    await pumpHome(AppThemeEnum.air, tab: 1);
    final field = find.byType(TextField);
    if (field.evaluate().isNotEmpty) {
      tester.widget<TextField>(field.first).controller?.text =
          locale == 'tr' ? 'kopnhag' : 'copenhagn';
    }
    await wait(0.5);
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(2.5);
    await shot('07-search');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('App Store screenshots', (tester) async {
    await installFakePlatform();
    final backend = FixtureBackend();
    HttpOverrides.global = FixtureHttpOverrides(backend);

    await ImageAspectRatioCache.instance.init();
    await initializeDateFormatting('tr', null);
    await initializeDateFormatting('en', null);
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final h = _Harness(tester, backend);
    final steps = <String, Future<void> Function()>{
      '01-feed': h.feed,
      '02-add': h.add,
      '03-reminder': h.reminder,
      '04-collections': h.collections,
      '05-share': h.share,
      '06-vault': h.vault,
      '07-search': h.search,
    };
    final only = _only.isEmpty ? null : _only.split(',').toSet();

    for (final locale in _locales.split(',')) {
      h.locale = locale;
      backend.locale = locale;
      for (final entry in steps.entries) {
        if (only != null && !only.contains(entry.key)) continue;
        debugPrint('🧪 [shots] $locale ${entry.key}');
        await entry.value();
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    // ignore: avoid_print
    print('SOMINE_SHOTS_DONE');
  }, timeout: Timeout.none);
}
