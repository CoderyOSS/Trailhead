import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/packages_api.dart';

final packagesApiProvider = Provider<PackagesApi>((ref) {
  return PackagesApi('');
});

/// Live packages state (installed + pending). Refresh via `ref.invalidate()`.
final packagesStateProvider = FutureProvider<PackagesState>((ref) async {
  return ref.read(packagesApiProvider).state();
});

/// Search query text in the Packages section. Empty = no search.
final packageSearchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced search results for the current query. Auto-re-runs when the
/// query changes.
final packageSearchResultsProvider =
    FutureProvider<List<HexSearchResult>>((ref) async {
  final query = ref.watch(packageSearchQueryProvider).trim();
  if (query.isEmpty) return const [];
  return ref.read(packagesApiProvider).search(query);
});

/// Cached release list per package name. Used by the version dropdown on
/// each installed row.
final packageReleasesProvider =
    FutureProvider.family<List<String>, String>((ref, name) async {
  if (name.isEmpty) return const [];
  return ref.read(packagesApiProvider).releases(name);
});
