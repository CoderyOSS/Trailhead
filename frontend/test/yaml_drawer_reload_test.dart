import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/api_provider.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/providers/mock_data.dart';
import 'package:frontend/services/workflows_api.dart';
import 'package:frontend/widgets/yaml_drawer.dart';

class FakeWorkflowsApi extends WorkflowsApi {
  FakeWorkflowsApi() : super('');

  int getCalls = 0;

  @override
  Future<WorkflowDto> get(String name) async {
    getCalls++;
    return WorkflowDto(
      name: name,
      content:
          'name: $name\nversion: 2\nproject: /tmp/reloaded\nnodes: []\n',
    );
  }
}

void main() {
  testWidgets('reload refetches workflow YAML and updates workflowProvider',
      (tester) async {
    final api = FakeWorkflowsApi();
    const wf = WorkflowSummary(
      id: 'wf_w',
      name: 'w',
      version: 1,
      updated: '',
    );

    final container = ProviderContainer(overrides: [
      workflowProvider.overrideWith((ref) => wf),
      workflowsApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: YamlDrawer(workflow: wf, onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(workflowProvider).project, isNull);

    await tester.tap(find.byKey(const Key('yaml_reload_button')));
    await tester.pumpAndSettle();

    expect(api.getCalls, 1);
    final updated = container.read(workflowProvider);
    expect(updated.project, '/tmp/reloaded');
    expect(updated.version, 2);
  });
}
