import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/modules_api.dart';

final modulesApiProvider = Provider<ModulesApi>((ref) {
  return ModulesApi('');
});

/// All registered modules (project links + registered dirs + global packages).
/// Drives the Modules settings section. Refresh by `ref.invalidate()`.
final registeredModulesProvider =
    FutureProvider<List<InstalledModule>>((ref) async {
  return ref.read(modulesApiProvider).list();
});

/// Per-subflow metadata (params + ports) for the canvas drawer when a
/// `type: subflow` node is selected. Key format: `"module:subflow"`.
final subflowMetaProvider =
    FutureProvider.family<SubflowMeta, ({String module, String subflow})>(
        (ref, key) async {
  return ref.read(modulesApiProvider).subflowMeta(key.module, key.subflow);
});

/// Flattened list of every available subflow across all modules, for the
/// subflow node picker dropdown in the canvas drawer.
Future<List<({String module, String subflow, String label})>>
    availableSubflows(WidgetRef ref) async {
  final modules = await ref.read(registeredModulesProvider.future);
  final out = <({String module, String subflow, String label})>[];
  for (final m in modules) {
    for (final s in m.subflows) {
      out.add((module: m.name, subflow: s, label: '${m.name} / $s'));
    }
  }
  return out;
}
