import 'dart:convert';
import 'package:http/http.dart' as http;

class ModulesApiException implements Exception {
  final int statusCode;
  final String body;
  ModulesApiException(this.statusCode, this.body);
  @override
  String toString() => 'ModulesApiException($statusCode): $body';
}

class ModuleNodeType {
  final String shortType;
  final String fullType;
  final String module;
  final bool actor;
  final String label;
  final String desc;

  const ModuleNodeType({
    required this.shortType,
    required this.fullType,
    required this.module,
    required this.actor,
    required this.label,
    required this.desc,
  });

  factory ModuleNodeType.fromJson(Map<String, dynamic> j) => ModuleNodeType(
        shortType: j['short_type'] as String? ?? '',
        fullType: j['full_type'] as String? ?? '',
        module: j['module'] as String? ?? '',
        actor: j['actor'] as bool? ?? false,
        label: j['label'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
      );
}

enum ModuleOrigin { project, registered, global }

ModuleOrigin _originFromString(String? s) {
  switch (s) {
    case 'project':
      return ModuleOrigin.project;
    case 'registered':
      return ModuleOrigin.registered;
    case 'global':
      return ModuleOrigin.global;
    default:
      return ModuleOrigin.global;
  }
}

class InstalledModule {
  final String name;
  final String? version;
  final String sourcePath;
  final String linkName;
  final ModuleOrigin origin;
  final List<ModuleNodeType> nodeTypes;
  final List<String> subflows;

  const InstalledModule({
    required this.name,
    required this.version,
    required this.sourcePath,
    required this.linkName,
    required this.origin,
    required this.nodeTypes,
    required this.subflows,
  });

  factory InstalledModule.fromJson(Map<String, dynamic> j) => InstalledModule(
        name: j['name'] as String? ?? '',
        version: j['version'] as String?,
        sourcePath: j['source_path'] as String? ?? '',
        linkName: j['link_name'] as String? ?? '',
        origin: _originFromString(j['origin'] as String?),
        nodeTypes: ((j['node_types'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(ModuleNodeType.fromJson)
            .toList(),
        subflows: ((j['subflows'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

class SubflowMeta {
  final String name;
  final List<String> params;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final String source;

  const SubflowMeta({
    required this.name,
    required this.params,
    required this.inputs,
    required this.outputs,
    required this.source,
  });

  factory SubflowMeta.fromJson(Map<String, dynamic> j) => SubflowMeta(
        name: j['name'] as String? ?? '',
        params: ((j['params'] as List?) ?? []).map((e) => e.toString()).toList(),
        inputs: (j['inputs'] as Map?)?.cast<String, dynamic>() ?? const {},
        outputs: (j['outputs'] as Map?)?.cast<String, dynamic>() ?? const {},
        source: j['source'] as String? ?? '',
      );
}

class ModulesApi {
  final String _baseUrl;
  final http.Client _client;

  ModulesApi(this._baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  Future<List<InstalledModule>> list() async {
    final resp = await _get('/api/v1/modules');
    if (resp.statusCode != 200) {
      throw ModulesApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as List;
    return body
        .cast<Map<String, dynamic>>()
        .map(InstalledModule.fromJson)
        .toList();
  }

  Future<SubflowMeta> subflowMeta(String moduleName, String subflowName) async {
    final resp = await _get(
      '/api/v1/modules/${Uri.encodeComponent(moduleName)}/subflows/${Uri.encodeComponent(subflowName)}/meta',
    );
    if (resp.statusCode != 200) {
      throw ModulesApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return SubflowMeta.fromJson(body);
  }

  Future<void> register(String path) async {
    final resp = await _post('/api/v1/modules/register', {'path': path});
    if (resp.statusCode != 200) {
      throw ModulesApiException(resp.statusCode, resp.body);
    }
  }

  Future<void> unregister(String path) async {
    final resp = await _client.delete(
      _uri('/api/v1/modules/register'),
      headers: _headers(),
      body: jsonEncode({'path': path}),
    );
    if (resp.statusCode != 200) {
      throw ModulesApiException(resp.statusCode, resp.body);
    }
  }

  Future<void> reload() async {
    final resp = await _post('/api/v1/modules/reload', {});
    if (resp.statusCode != 200) {
      throw ModulesApiException(resp.statusCode, resp.body);
    }
  }

  // ---- HTTP plumbing ----

  Uri _uri(String path) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$base$path');
  }

  Future<http.Response> _get(String path) =>
      _client.get(_uri(path), headers: _headers());

  Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      _client.post(_uri(path), headers: _headers(), body: jsonEncode(body));

  Map<String, String> _headers() => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
