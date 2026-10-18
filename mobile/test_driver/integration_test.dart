import 'package:integration_test/integration_test_driver.dart';

// integration_test/ altındaki testler için `flutter drive` sürücüsü
// (ekran görüntüsü düzeneği: integration_test/app_store_screenshots_test.dart).
Future<void> main() => integrationDriver(timeout: const Duration(minutes: 40));
