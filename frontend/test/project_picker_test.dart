import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/providers/mock_data.dart';
import 'package:frontend/providers/thrt_provider.dart';
import 'package:frontend/services/thrt_api.dart';
import 'package:frontend/widgets/project_picker.dart';

void main() {
  const wf = WorkflowSummary(
    id: 'wf_w',
    name: 'w',
    version: 1,
    updated: '',
  );

  const projects = ThrtProjects(
    current: '/home/gem/projects/TrailheadTests',
    registered: ['/home/gem/projects/Other'],
    packages: ['gpkg'],
  );

  Widget harness(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ProjectPicker())),
    );
  }

  testWidgets('lists none, current project, and registered projects',
      (tester) async {
    final container = ProviderContainer(overrides: [
      workflowProvider.overrideWith((ref) => wf),
      projectsProvider.overrideWith((ref) async => projects),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();

    expect(find.text('no project').hitTestable(), findsWidgets);
    expect(
      find.text('/home/gem/projects/TrailheadTests').hitTestable(),
      findsWidgets,
    );
    expect(find.text('/home/gem/projects/Other').hitTestable(), findsWidgets);
  });

  testWidgets('selecting a project sets workflowProvider.project',
      (tester) async {
    final container = ProviderContainer(overrides: [
      workflowProvider.overrideWith((ref) => wf),
      projectsProvider.overrideWith((ref) async => projects),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/home/gem/projects/TrailheadTests').last);
    await tester.pumpAndSettle();

    expect(container.read(workflowProvider).project,
        '/home/gem/projects/TrailheadTests');
  });

  testWidgets('selecting no project clears workflowProvider.project',
      (tester) async {
    final container = ProviderContainer(overrides: [
      workflowProvider
          .overrideWith((ref) => wf.copyWith(project: '/tmp/somewhere')),
      projectsProvider.overrideWith((ref) async => projects),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('no project').last);
    await tester.pumpAndSettle();

    expect(container.read(workflowProvider).project, isNull);
  });
}
