import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/workflow_node.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/providers/mock_data.dart';
import 'package:frontend/providers/operator_picker_provider.dart';
import 'package:frontend/providers/selection_notifier.dart';
import 'package:frontend/providers/thrt_provider.dart';
import 'package:frontend/services/thrt_api.dart';
import 'package:frontend/widgets/canvas/graph_canvas.dart';

void main() {
  testWidgets('backspace in picker search field does not delete selected node',
      (tester) async {
    const node = WorkflowNode(id: 'n1', kind: 'task', label: 'task', x: 0, y: 0);
    final wf = WorkflowSummary(
      id: 'wf1',
      name: 'wf',
      version: 1,
      updated: '',
      nodes: [node],
    );

    final container = ProviderContainer(
      overrides: [
        workflowProvider.overrideWith((ref) => wf),
        installedNodesProvider.overrideWith(
          (ref) async => const <InstalledNode>[],
        ),
        jobsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: GraphCanvas())),
      ),
    );
    await tester.pumpAndSettle();

    container.read(selectionProvider.notifier).selectOne('n1');

    // Open the picker, as a canvas double-click would.
    container.read(operatorPickerProvider.notifier).state =
        const PickerAnchor(screenPos: Offset(100, 100));
    await tester.pumpAndSettle();

    // Focus the picker search field, as a user clicking into it would.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final pfCtx = FocusManager.instance.primaryFocus?.context;
    expect(
      pfCtx != null &&
          (pfCtx.widget is EditableText ||
              pfCtx.findAncestorWidgetOfExactType<EditableText>() != null),
      isTrue,
      reason: 'search field should hold primary focus before backspace',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(
      container.read(workflowProvider).nodes,
      hasLength(1),
      reason: 'backspace while a text field is focused must not delete nodes',
    );
  });
}
