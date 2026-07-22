import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/carta_api.dart';
import 'package:frontend/utils/workflow_to_yaml.dart';
import 'package:frontend/utils/yaml_to_workflow.dart';

void main() {
  group('project field round-trip', () {
    test('yamlToWorkflow parses top-level project:', () {
      final wf = yamlToWorkflow('w', '''
name: w
version: 1
project: /home/gem/projects/CartaTests
nodes: []
''');
      expect(wf.project, '/home/gem/projects/CartaTests');
    });

    test('yamlToWorkflow without project: leaves it null', () {
      final wf = yamlToWorkflow('w', 'name: w\nversion: 1\nnodes: []\n');
      expect(wf.project, isNull);
    });

    test('workflowToYaml never emits project: (deprecated key)', () {
      final wf = yamlToWorkflow('w', '''
name: w
version: 1
project: /home/gem/projects/CartaTests
nodes: []
''');
      expect(workflowToYaml(wf), isNot(contains('project:')));
    });

    test('workflowToYaml omits project when null', () {
      final wf = yamlToWorkflow('w', 'name: w\nversion: 1\nnodes: []\n');
      expect(workflowToYaml(wf), isNot(contains('project:')));
    });

    test('copyWith can set and clear project', () {
      final wf = yamlToWorkflow('w', 'name: w\nversion: 1\nnodes: []\n');
      final set = wf.copyWith(project: '/tmp/x');
      expect(set.project, '/tmp/x');
      final cleared = set.copyWith(project: null);
      expect(cleared.project, isNull);
      // Unset keeps existing value.
      expect(set.copyWith(name: 'w').project, '/tmp/x');
    });
  });

  group('InstalledNode package identity', () {
    test('fromJson parses package and version', () {
      final n = InstalledNode.fromJson(const {
        'type': 'mod.carta_ai_node.harness',
        'module': 'Elixir.X',
        'actor': true,
        'label': 'harness',
        'desc': 'd',
        'package': 'carta_ai_node',
        'version': '0.1.0',
      });
      expect(n.package, 'carta_ai_node');
      expect(n.version, '0.1.0');
    });

    test('fromJson tolerates missing package/version (builtins)', () {
      final n = InstalledNode.fromJson(const {
        'type': 'function',
        'module': 'Elixir.Carta.Nodes.Function',
        'actor': false,
        'label': 'function',
        'desc': '',
      });
      expect(n.package, isNull);
      expect(n.version, isNull);
    });
  });
}
