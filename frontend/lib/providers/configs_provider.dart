import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/configs_api.dart';

final configsApiProvider = Provider<ConfigsApi>((ref) {
  return ConfigsApi('/api/v1');
});

/// All configuration objects in the open project (configs/*.yaml). Refresh by
/// `ref.invalidate(configsProvider)`.
final configsProvider = FutureProvider<List<ConfigDto>>((ref) async {
  return ref.read(configsApiProvider).list();
});
