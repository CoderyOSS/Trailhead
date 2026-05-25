import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'widgets/mode_rail.dart';
import 'widgets/top_bar.dart';

void main() {
  runApp(const TrailheadApp());
}

class TrailheadApp extends StatelessWidget {
  const TrailheadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Trailhead',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.bg0,
        ),
        home: const TrailheadShell(),
      ),
    );
  }
}

class TrailheadShell extends ConsumerWidget {
  const TrailheadShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const ModeRail(activeCount: 3),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: Container(color: AppColors.bg1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
