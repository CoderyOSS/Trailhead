import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/workflow_to_yaml.dart';
import 'package:frontend/utils/yaml_to_workflow.dart';

void main() {
  group('config_key round-trip', () {
    const yaml = '''
name: w
version: 1
nodes:
  - id: "a"
    type: function
    label: "a"
    config:
      expr: |
        payload
      config_key: "db"
connections: []
''';

    test('yamlToWorkflow parses config.config_key', () {
      final wf = yamlToWorkflow('w', yaml);
      expect(wf.nodes.single.configKey, 'db');
    });

    test('workflowToYaml emits config_key when set', () {
      final wf = yamlToWorkflow('w', yaml);
      expect(workflowToYaml(wf), contains('config_key: "db"'));
    });

    test('config_key round-trips through emit+parse', () {
      final reparsed = yamlToWorkflow('w', workflowToYaml(yamlToWorkflow('w', yaml)));
      expect(reparsed.nodes.single.configKey, 'db');
    });

    test('absent config_key parses to null and is not emitted', () {
      const noKey = '''
name: w
version: 1
nodes:
  - id: "a"
    type: function
    label: "a"
    config:
      expr: |
        payload
connections: []
''';
      final wf = yamlToWorkflow('w', noKey);
      expect(wf.nodes.single.configKey, isNull);
      expect(workflowToYaml(wf), isNot(contains('config_key')));
    });

    test('config_key emits a config block even with no other config (universal)', () {
      // A node may pull its ENTIRE config from a stored object — config_key
      // alone must still produce a `config:` block, regardless of kind.
      const yaml = '''
name: w
version: 1
nodes:
  - id: "a"
    type: task
    label: "a"
    config:
      config_key: "db"
connections: []
''';
      final wf = yamlToWorkflow('w', yaml);
      expect(wf.nodes.single.configKey, 'db');
      final emitted = workflowToYaml(wf);
      expect(emitted, contains('config:'));
      expect(emitted, contains('config_key: "db"'));
    });
  });
}
