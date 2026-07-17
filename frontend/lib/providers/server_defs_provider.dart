import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_def.dart';

final serverDefsProvider = StateProvider<List<ServerDef>>((ref) => []);
