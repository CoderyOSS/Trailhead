import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/node_catalog.dart';
import 'package:frontend/services/carta_api.dart';

void main() {
  // Pure logic check: the category list the picker assembles must keep
  // INSTALLED MODULES between ACTORS (first) and FUNCTIONS. This is the
  // contract the rendering relies on; verifying it directly avoids the
  // fragile "render and check y-coordinate" path, which broke when ACTORS
  // grew past the picker's 440px maxHeight (off-screen categories stopped
  // building under lazy ListView virtualization).
  test('installedModulesCategory lands between ACTORS and FUNCTIONS', () {
    const harness = InstalledNode(
      type: 'harness',
      module: 'X.Harness',
      actor: true,
      label: 'harness',
      desc: 'd',
    );
    final installed = installedModulesCategory(const [harness])!;

    final labels = <String>[
      nodeCategories.first.label, // ACTORS
      subflowCategory.label, // COMPOSE
      installed.label, // INSTALLED MODULES
      ...nodeCategories.skip(1).map((c) => c.label), // FUNCTIONS, ...
    ];
    expect(labels.indexOf('ACTORS'), lessThan(labels.indexOf('INSTALLED MODULES')));
    expect(
      labels.indexOf('INSTALLED MODULES'),
      lessThan(labels.indexOf('FUNCTIONS')),
    );
  });
}
