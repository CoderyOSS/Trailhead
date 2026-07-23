import 'dart:convert';

import 'package:http/http.dart' as http;

class ConfigDto {
  final String key;
  final String source;
  final String? updatedAt;

  const ConfigDto({
    required this.key,
    required this.source,
    this.updatedAt,
  });

  factory ConfigDto.fromJson(Map<String, dynamic> json) {
    return ConfigDto(
      key: json['key'] as String,
      source: json['source'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class ConfigsApiException implements Exception {
  final int statusCode;
  final String body;
  ConfigsApiException(this.statusCode, this.body);
  @override
  String toString() => 'ConfigsApiException($statusCode): $body';
}

/// CRUD for project configuration objects (named Elixir literals stored
/// server-side in configs/*.yaml). Mirrors SubflowsApi against /api/v1/configs.
/// No project param — the backend scopes to the current project (like subflows).
class ConfigsApi {
  final String _baseUrl;
  final http.Client _client;

  ConfigsApi(this._baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  Future<List<ConfigDto>> list() async {
    final resp = await _get('/configs');
    final body = jsonDecode(resp.body);
    if (body is! List) {
      throw ConfigsApiException(resp.statusCode, 'expected list, got ${body.runtimeType}');
    }
    return body.cast<Map<String, dynamic>>().map(ConfigDto.fromJson).toList();
  }

  Future<ConfigDto> get(String key) async {
    final resp = await _get('/configs/${Uri.encodeComponent(key)}');
    _ensureOk(resp, [200]);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return ConfigDto.fromJson(body);
  }

  Future<void> create(String key, String source) async {
    final resp = await _post('/configs', {'key': key, 'source': source});
    _ensureOk(resp, [201]);
  }

  Future<void> replace(String key, String source) async {
    final resp = await _put('/configs/${Uri.encodeComponent(key)}', {'source': source});
    _ensureOk(resp, [200]);
  }

  Future<void> delete(String key) async {
    final resp = await _delete('/configs/${Uri.encodeComponent(key)}');
    _ensureOk(resp, [204]);
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

  Future<http.Response> _put(String path, Map<String, dynamic> body) =>
      _client.put(_uri(path), headers: _headers(), body: jsonEncode(body));

  Future<http.Response> _delete(String path) =>
      _client.delete(_uri(path), headers: _headers());

  Map<String, String> _headers() => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _ensureOk(http.Response resp, List<int> allowed) {
    if (!allowed.contains(resp.statusCode)) {
      throw ConfigsApiException(resp.statusCode, resp.body);
    }
  }
}
