import 'package:somine_app/core/config/api_config.dart';

/// Builds the read-only public web URL (`{publicWebBaseUrl}/s/{token}`) for a
/// share or collection public link token.
String publicLinkUrlFromToken(String token) {
  final base = ApiConfig.publicWebBaseUrl.replaceFirst(RegExp(r'/$'), '');
  return '$base/s/$token';
}
