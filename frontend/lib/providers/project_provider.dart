import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/project_api.dart';

final projectApiProvider = Provider<ProjectApi>((ref) {
  return ProjectApi('/api/v1');
});

/// The connected Carta instance's open project (dir, mode, Carta source,
/// install dir, flow tab order). Drives the Instance settings section and
/// (later) the TopBar flow tabs. Refresh by `ref.invalidate()`.
final projectInfoProvider = FutureProvider<ProjectInfo>((ref) async {
  return ref.read(projectApiProvider).get();
});
