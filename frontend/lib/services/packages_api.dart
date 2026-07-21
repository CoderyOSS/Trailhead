import 'dart:convert';
import 'package:http/http.dart' as http;

class PackagesApiException implements Exception {
  final int statusCode;
  final String body;
  PackagesApiException(this.statusCode, this.body);
  @override
  String toString() => 'PackagesApiException($statusCode): $body';
}

class HexSearchResult {
  final String name;
  final String description;
  final String url;
  final String? version;

  const HexSearchResult({
    required this.name,
    required this.description,
    required this.url,
    required this.version,
  });

  factory HexSearchResult.fromJson(Map<String, dynamic> j) => HexSearchResult(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        url: j['url'] as String? ?? '',
        version: j['version'] as String?,
      );
}

class InstalledPackage {
  final String name;
  final String version;
  final String? installedAt;
  final String? status;
  final String? reason;

  const InstalledPackage({
    required this.name,
    required this.version,
    this.installedAt,
    this.status,
    this.reason,
  });

  bool get hasError => status == 'error';

  factory InstalledPackage.fromJson(Map<String, dynamic> j) => InstalledPackage(
        name: j['name'] as String? ?? '',
        version: j['version'] as String? ?? '',
        installedAt: j['installed_at'] as String?,
        status: j['status'] as String?,
        reason: j['reason'] as String?,
      );
}

class PackagesState {
  final List<InstalledPackage> installed;
  final List<InstalledPackage> pendingInstalls;
  final List<String> pendingUninstalls;

  const PackagesState({
    required this.installed,
    required this.pendingInstalls,
    required this.pendingUninstalls,
  });

  int get pendingCount => pendingInstalls.length + pendingUninstalls.length;

  factory PackagesState.fromJson(Map<String, dynamic> j) {
    final installed = ((j['installed'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(InstalledPackage.fromJson)
        .toList();
    final pendingMap = (j['pending'] as Map?) ?? const {};
    final pendingInstalls = ((pendingMap['install'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(InstalledPackage.fromJson)
        .toList();
    final pendingUninstalls = ((pendingMap['uninstall'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    return PackagesState(
      installed: installed,
      pendingInstalls: pendingInstalls,
      pendingUninstalls: pendingUninstalls,
    );
  }
}

class PackagesApi {
  final String _baseUrl;
  final http.Client _client;

  PackagesApi(this._baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  Future<List<HexSearchResult>> search(String query) async {
    final resp = await _get('/api/v1/packages/search?q=${Uri.encodeQueryComponent(query)}');
    if (resp.statusCode != 200) {
      throw PackagesApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as List;
    return body
        .cast<Map<String, dynamic>>()
        .map(HexSearchResult.fromJson)
        .toList();
  }

  Future<List<String>> releases(String name) async {
    final resp = await _get('/api/v1/packages/${Uri.encodeComponent(name)}/releases');
    if (resp.statusCode != 200) {
      throw PackagesApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return ((body['versions'] as List?) ?? []).map((e) => e.toString()).toList();
  }

  Future<PackagesState> state() async {
    final resp = await _get('/api/v1/packages');
    if (resp.statusCode != 200) {
      throw PackagesApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return PackagesState.fromJson(body);
  }

  Future<List<InstalledPackage>> install(String name, String version) async {
    final resp = await _post(
      '/api/v1/packages/${Uri.encodeComponent(name)}/install',
      {'version': version},
    );
    if (resp.statusCode != 200) {
      throw PackagesApiException(resp.statusCode, resp.body);
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return ((body['install'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(InstalledPackage.fromJson)
        .toList();
  }

  Future<void> uninstall(String name) async {
    final resp = await _client.delete(
      _uri('/api/v1/packages/${Uri.encodeComponent(name)}'),
      headers: _headers(),
    );
    if (resp.statusCode != 200) {
      throw PackagesApiException(resp.statusCode, resp.body);
    }
  }

  Future<void> restart() async {
    final resp = await _post('/api/v1/system/restart', {});
    if (resp.statusCode != 200) {
      throw PackagesApiException(resp.statusCode, resp.body);
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
