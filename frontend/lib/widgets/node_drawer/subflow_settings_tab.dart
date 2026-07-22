import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workflow_node.dart';
import '../../providers/flow_tabs_provider.dart';
import '../../providers/mode_provider.dart';
import '../../providers/modules_provider.dart';
import '../../providers/subflows_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_button.dart';
import '../../widgets/icons.dart';
import '../../widgets/mode_rail.dart';
import 'node_drawer.dart' show Field;

/// Drawer body for `type: subflow` nodes. Lets the user pick which packaged
/// subflow to embed and binds its declared `params` to node config values.
///
/// Config schema (emitted to YAML as a single `config:` block):
///   config:
///     subflow: <name>          # picked from dropdown
///     <param>: <value>         # one entry per declared param
class SubflowSettingsTab extends ConsumerStatefulWidget {
  final WorkflowNode node;

  const SubflowSettingsTab({super.key, required this.node});

  @override
  ConsumerState<SubflowSettingsTab> createState() => _SubflowSettingsTabState();
}

class _SubflowSettingsTabState extends ConsumerState<SubflowSettingsTab> {
  String? _selectedModule;
  String? _selectedSubflow;
  Map<String, String> _paramValues = {};

  @override
  void initState() {
    super.initState();
    _initFromNode();
  }

  void _initFromNode() {
    final cfg = widget.node.config ?? {};
    final subflow = cfg['subflow'] as String?;
    if (subflow != null && subflow.contains('/')) {
      final parts = subflow.split('/');
      _selectedModule = parts[0];
      _selectedSubflow = parts[1];
    }
    for (final entry in cfg.entries) {
      if (entry.key == 'subflow') continue;
      _paramValues[entry.key] = entry.value.toString();
    }
  }

  void _persist() {
    final cfg = <String, dynamic>{};
    if (_selectedModule != null && _selectedSubflow != null) {
      cfg['subflow'] = '$_selectedModule/$_selectedSubflow';
    }
    cfg.addAll(_paramValues);
    updateCanvasNode(ref, widget.node.id, (n) => n.copyWith(config: cfg));
  }

  /// Resolve the node's selected subflow to a project subflow (subflows/
  /// dir, listed by the CRUD) and open it as a tab. Packaged subflows only
  /// land locally on first deploy — if there is no local copy yet, say so.
  Future<void> _openSubflowTab(BuildContext context) async {
    final full = '$_selectedModule/$_selectedSubflow';
    final subflows = ref.read(subflowsProvider).valueOrNull ?? [];
    String? localName;
    for (final s in subflows) {
      if (s.name == full || s.name == _selectedSubflow) {
        localName = s.name;
        break;
      }
    }
    if (localName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'no local copy yet — deploy once to copy this subflow into the project'),
        ),
      );
      return;
    }
    await openSubflowTab(ref, localName);
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(registeredModulesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description banner.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              border: Border.all(color: AppColors.border2, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CartaIcon(
                    icon: CartaIconData.workflow,
                    size: 14,
                    color: AppColors.fg2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A subflow node embeds a packaged flow graph. On first '
                    'deploy the backend copies the definition into your '
                    'project\'s subflows/ directory — you can then edit the '
                    'local copy.',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg2,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Field(
            label: 'subflow',
            child: modulesAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.fg2)),
              ),
              error: (e, _) => Text('Failed to load modules: $e',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.danger)),
              data: (modules) {
                // Build a flat list of (module, subflow, label) tuples.
                final options = <_SubflowOption>[];
                for (final m in modules) {
                  for (final s in m.subflows) {
                    options.add(_SubflowOption(
                        module: m.name, subflow: s, label: '${m.name} / $s'));
                  }
                }
                if (options.isEmpty) {
                  return Text('No subflows available — register a module first.',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.fg2));
                }
                final selected = (_selectedModule != null && _selectedSubflow != null)
                    ? '$_selectedModule/$_selectedSubflow'
                    : null;
                final matching = options
                    .where((o) => '${o.module}/${o.subflow}' == selected)
                    .toList();
                final value = matching.isNotEmpty ? matching.first.label : null;
                return _SubflowDropdown(
                  value: value,
                  options: options,
                  onChanged: (opt) {
                    setState(() {
                      _selectedModule = opt?.module;
                      _selectedSubflow = opt?.subflow;
                      _paramValues.clear();
                    });
                    _persist();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Open the project's local copy of this subflow as a TopBar tab.
          if (_selectedModule != null &&
              _selectedSubflow != null &&
              ref.watch(modeProvider) == AppMode.build)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  icon: CartaIconData.pencil,
                  label: 'edit subflow',
                  onTap: () => _openSubflowTab(context),
                ),
              ),
            ),

          // Param fields (loaded from subflow meta).
          if (_selectedModule != null && _selectedSubflow != null)
            _ParamFields(
              module: _selectedModule!,
              subflow: _selectedSubflow!,
              initialValues: _paramValues,
              onParamChanged: (key, value) {
                setState(() => _paramValues[key] = value);
                _persist();
              },
            ),
        ],
      ),
    );
  }
}

class _SubflowOption {
  final String module;
  final String subflow;
  final String label;
  const _SubflowOption({
    required this.module,
    required this.subflow,
    required this.label,
  });
}

class _SubflowDropdown extends StatelessWidget {
  final String? value;
  final List<_SubflowOption> options;
  final void Function(_SubflowOption?) onChanged;

  const _SubflowDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String?>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(
            fontFamily: 'monospace', fontSize: 12, color: AppColors.fg0),
        dropdownColor: AppColors.bg2,
        hint: Text('pick a packaged subflow…',
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.fg3)),
        items: options
            .map((o) => DropdownMenuItem(
                  value: o.label,
                  child: Text(o.label),
                ))
            .toList(),
        onChanged: (label) {
          final match = options.where((o) => o.label == label).toList();
          onChanged(match.isEmpty ? null : match.first);
        },
      ),
    );
  }
}

class _ParamFields extends ConsumerWidget {
  final String module;
  final String subflow;
  final Map<String, String> initialValues;
  final void Function(String key, String value) onParamChanged;

  const _ParamFields({
    required this.module,
    required this.subflow,
    required this.initialValues,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metaAsync = ref.watch(
        subflowMetaProvider((module: module, subflow: subflow)));

    return metaAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.fg2)),
      ),
      error: (e, _) => Text('Failed to load subflow meta: $e',
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 11, color: AppColors.danger)),
      data: (meta) {
        if (meta.params.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('This subflow has no params.',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.fg3,
                    fontStyle: FontStyle.italic)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PARAMS',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 0.06 * 10,
                    color: AppColors.fg3,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final p in meta.params)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Field(
                  label: p,
                  child: _ParamInput(
                    initialValue: initialValues[p] ?? '',
                    onChanged: (v) => onParamChanged(p, v),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ParamInput extends StatefulWidget {
  final String initialValue;
  final void Function(String value) onChanged;

  const _ParamInput({required this.initialValue, required this.onChanged});

  @override
  State<_ParamInput> createState() => _ParamInputState();
}

class _ParamInputState extends State<_ParamInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: TextStyle(
          fontFamily: 'monospace', fontSize: 12, color: AppColors.fg0),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        hintText: 'value',
        hintStyle: TextStyle(
            fontFamily: 'monospace', fontSize: 11.5, color: AppColors.fg3),
        filled: true,
        fillColor: AppColors.bg0,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.border2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.border2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.accent)),
      ),
    );
  }
}
