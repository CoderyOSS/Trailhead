import 'dart:convert';

import 'package:http/http.dart' as http;

/// The Carta instance's open project, from GET /api/v1/project. In
/// local-install mode Carta is a Mix dependency of the project, so the
/// project dir is fixed at boot (cwd) and there is no folder switching.
class ProjectInfo {
  final String dir;
  final String mode;
  final String? cartaSource;
  final String installDir;
  final List<String> flowOrder;

  const ProjectInfo({
    required this.dir,
    required this.mode,
    this.cartaSource,
    required this.installDir,
    this.flowOrder = const [],
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      dir: json['dir'] as String? ?? '',
      mode: json['mode'] as String? ?? 'local',
      cartaSource: json['carta_source'] as String?,
      installDir: json['install_dir'] as String? ?? '',
      flowOrder:
          (json['flow_order'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class ProjectApiException implements Exception {
  final int statusCode;
  final String body;
  ProjectApiException(this.statusCode, this.body);
  @override
  String toString() => 'ProjectApiException($statusCode): $body';
}

class ProjectApi {
  final String _baseUrl;
  final http.Client _client;

  ProjectApi(this._baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  Future<ProjectInfo> get() async {
    final resp = await _get('/project');
    _ensureOk(resp, [200]);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return ProjectInfo.fromJson(body);
  }

  /// Persist the flow tab order. Body is a bare JSON array of flow names
  /// (unknown names are rejected 422 server-side).
  Future<void> putFlowOrder(List<String> names) async {
    final resp = await _client.put(
      _uri('/project/flow-order'),
      headers: _headers(),
      body: jsonEncode(names),
    );
    _ensureOk(resp, [200]);
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

  Map<String, String> _headers() => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _ensureOk(http.Response resp, List<int> allowed) {
    if (!allowed.contains(resp.statusCode)) {
      throw ProjectApiException(resp.statusCode, resp.body);
    }
  }
}
