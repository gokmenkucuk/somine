import 'package:url_launcher/url_launcher.dart';

/// Gizlilik politikası, kullanım koşulları gibi web sayfalarını uygulamadan
/// çıkmadan açar: iOS'ta SFSafariViewController (alttan açılan, "Bitti" ile
/// kapanan Safari sayfası). Açılamazsa harici tarayıcıya düşer.
Future<void> openInAppLink(String url) async {
  final uri = Uri.parse(url);
  try {
    if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return;
  } catch (_) {}
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
