import 'dart:convert';
import 'package:http/http.dart' as http;

class ThrtApiException implements Exception {
  final int statusCode;
  final String body;
  ThrtApiException(this.statusCode, this.body);
  @override
  String toString() => 'ThrtApiException($statusCode): $body';
}

class FlowStatus {
  final bool deployed;
  final Map<String, ({int msgsIn, int msgsOut})> nodes;

  const FlowStatus({required this.deployed, this.nodes = const {}});

  factory FlowStatus.undeployed() => const FlowStatus(deployed: false);
}

/// A node type installed in the THRT runtime (builtin or from a project
/// `trailhead.yaml` `node_modules` entry). Drives the "new node" picker.
class InstalledNode {
  final String type;
  final String module;
  final bool actor;
  final String label;
  final String desc;

  /// Linked package identity for `mod.<package>.<type>` nodes; null for
  /// builtins and config-registered modules.
  final String? package;
  final String? version;

  const InstalledNode({
    required this.type,
    required this.module,
    required this.actor,
    required this.label,
    required this.desc,
    this.package,
    this.version,
  });

  factory InstalledNode.fromJson(Map<String, dynamic> j) => InstalledNode(
        type: j['type'] as String,
        module: j['module'] as String? ?? '',
        actor: j['actor'] as bool? ?? false,
        label: j['label'] as String? ?? (j['type'] as String),
        desc: j['desc'] as String? ?? '',
        package: j['package'] as String?,
        version: j['version'] as String?,
      );
}

/// Project registry from GET /api/v1/projects.
class ThrtProjects {
  /// The runtime's current/default project dir.
  final String current;

  /// Registered project dirs (~/.trailhead/projects.yaml).
  final List<String> registered;

  /// Global package names (~/.trailhead/packages/*).
  final List<String> packages;

  const ThrtProjects({
    required this.current,
    required this.registered,
    required this.packages,
  });

  /// All selectable project dirs: current first, then registered
  /// (deduplicated, order preserved).
  List<String> get dirs => [
        current,
        ...registered.where((d) => d != current),
      ];
}

class TermValidationResult {
  final bool ok;
  final String? error;
  final int? line;

  const TermValidationResult({required this.ok, this.error, this.line});

  factory TermValidationResult.good() => const TermValidationResult(ok: true);
  factory TermValidationResult.bad(String error, int? line) =>
      TermValidationResult(ok: false, error: error, line: line);
}

class ThrtApi {
  final String _baseUrl;
  final http.Client _client;

  ThrtApi(this._baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  /// List node modules installed in the runtime (builtins + project
  /// trailhead.yaml node_modules). Empty list on 404 (older runtime).
  Future<List<InstalledNode>> fetchNodes() async {
    final resp = await _get('/api/v1/nodes');
    if (resp.statusCode == 404) return const [];
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as List;
    return body
        .cast<Map<String, dynamic>>()
        .map(InstalledNode.fromJson)
        .toList();
  }

  /// Deploy an already-saved flow (must exist in THRT.Store).
  Future<void> deploy(String name) async {
    final resp = await _post('/api/v1/workflows/${Uri.encodeComponent(name)}/deploy', {});
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
  }

  Future<void> undeploy(String name) async {
    final resp = await _client.delete(
      _uri('/api/v1/workflows/${Uri.encodeComponent(name)}/deploy'),
    );
    if (resp.statusCode != 200 && resp.statusCode != 404) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
  }

  /// Get runtime status of a flow. Returns `deployed=false` if not running.
  Future<FlowStatus> status(String name) async {
    final resp = await _get('/api/v1/workflows/${Uri.encodeComponent(name)}/status');
    if (resp.statusCode == 404) return FlowStatus.undeployed();
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final nodesList = (body['nodes'] as List).cast<Map<String, dynamic>>();
    final nodes = <String, ({int msgsIn, int msgsOut})>{};
    for (final n in nodesList) {
      final id = n['node_id'] as String;
      nodes[id] = (
        msgsIn: (n['msgs_in'] as num).toInt(),
        msgsOut: (n['msgs_out'] as num).toInt(),
      );
    }
    return FlowStatus(deployed: true, nodes: nodes);
  }

  /// Inject a payload (Elixir source code, backend parses) into a running node.
  Future<void> injectCode(String name, String nodeId, String code) async {
    final resp = await _post('/api/v1/workflows/${Uri.encodeComponent(name)}/inject', {
      'node_id': nodeId,
      'code': code,
    });
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
  }

  /// Project registry: current dir, registered dirs, global packages.
  Future<ThrtProjects> fetchProjects() async {
    final resp = await _get('/api/v1/projects');
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return ThrtProjects(
      current: body['current'] as String? ?? '',
      registered:
          (body['registered'] as List? ?? []).map((e) => e.toString()).toList(),
      packages:
          (body['packages'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  /// Validate a workflow without deploying. Pass either [content] (YAML
  /// text) or [name] (stored workflow). Returns error strings, empty when
  /// valid. Backend always answers 200 with an `errors` array.
  Future<List<String>> validateWorkflow({
    String? name,
    String? content,
  }) async {
    final resp = await _post('/api/v1/workflows/validate', {
      if (content != null) 'content': content else 'name': name,
    });
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final errors = (body['errors'] as List? ?? []).cast<Map<String, dynamic>>();
    return errors.map((e) {
      final where = e['node'] ?? e['path'] ?? '?';
      return '$where: ${e['reason']}';
    }).toList();
  }

  /// Validate an Elixir term literal against the backend literal parser.
  Future<TermValidationResult> validateElixirTerm(String code) async {
    final resp = await _post('/api/v1/validate/elixir-term', {'code': code});
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final ok = (body['ok'] as bool?) ?? false;
    if (ok) return TermValidationResult.good();
    final err = body['error'] as String?;
    final line = body['line'] as int?;
    return TermValidationResult.bad(err ?? 'invalid', line);
  }

  /// Hot-toggle log_in / log_out for a running node without redeploy.
  Future<void> setLogFlags(
    String name,
    String nodeId, {
    bool? logIn,
    bool? logOut,
  }) async {
    final body = <String, dynamic>{'node_id': nodeId};
    if (logIn != null) body['log_in'] = logIn;
    if (logOut != null) body['log_out'] = logOut;

    final resp = await _patch(
      '/api/v1/workflows/${Uri.encodeComponent(name)}/log-flags',
      body,
    );
    if (resp.statusCode != 200) {
      throw ThrtApiException(resp.statusCode, resp.body);
    }
  }

  /// WebSocket URL for the per-flow log stream.
  String logsStreamUrl(String name) {
    // Empty base = same-origin deployment: derive from the browser page
    // origin so scheme/host are never empty (and https maps to wss).
    final effectiveBase =
        _baseUrl.isEmpty ? Uri.base.origin : _baseUrl;
    final base = effectiveBase.endsWith('/')
        ? effectiveBase.substring(0, effectiveBase.length - 1)
        : effectiveBase;
    final wsScheme = base.startsWith('https') ? 'wss' : 'ws';
    final host = base.replaceFirst(RegExp(r'^https?://'), '');
    return '$wsScheme://$host/api/v1/workflows/${Uri.encodeComponent(name)}/logs/stream';
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

  Future<http.Response> _patch(String path, Map<String, dynamic> body) =>
      _client.patch(_uri(path), headers: _headers(), body: jsonEncode(body));

  Map<String, String> _headers() => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
