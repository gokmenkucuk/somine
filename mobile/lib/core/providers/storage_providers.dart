import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/repositories/storage_repository.dart';

/// Storage repository provider
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});
