import 'dart:convert';

import 'package:http/http.dart' as http;

class SubflowDto {
  final String name;
  final String content;
  final String? contentHash;
  final String? updatedAt;

  const SubflowDto({
    required this.name,
    required this.content,
    this.contentHash,
    this.updatedAt,
  });

  factory SubflowDto.fromJson(Map<String, dynamic> json) {
    return SubflowDto(
      name: json['name'] as String,
      content: json['content'] as String,
      contentHash: json['content_hash'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class SubflowsApiException implements Exception {
  final int statusCode;
  final String body;
  SubflowsApiException(this.statusCode, this.body);
  @override
  String toString() => 'SubflowsApiException($statusCode): $body';
}

/// CRUD for project subflows (`subflows/<name>.yaml` on the Carta side).
/// Mirrors WorkflowsApi's shape against /api/v1/subflows.
class SubflowsApi {
  final String _baseUrl;
  final http.Client _client;

  SubflowsApi(this._baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  Future<List<SubflowDto>> list() async {
    final resp = await _get('/subflows');
    final body = jsonDecode(resp.body);
    if (body is! List) {
      throw SubflowsApiException(resp.statusCode, 'expected list, got ${body.runtimeType}');
    }
    return body
        .cast<Map<String, dynamic>>()
        .map(SubflowDto.fromJson)
        .toList();
  }

  Future<SubflowDto> get(String name) async {
    final resp = await _get('/subflows/${Uri.encodeComponent(name)}');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return SubflowDto.fromJson(body);
  }

  Future<void> create(String name, String content) async {
    final resp = await _post('/subflows', {'name': name, 'content': content});
    _ensureOk(resp, [200, 201]);
  }

  Future<void> replace(String name, String content) async {
    final resp = await _put('/subflows/${Uri.encodeComponent(name)}', {'content': content});
    _ensureOk(resp, [200]);
  }

  Future<bool> delete(String name) async {
    final resp = await _delete('/subflows/${Uri.encodeComponent(name)}');
    _ensureOk(resp, [200]);
    final body = jsonDecode(resp.body);
    if (body is Map<String, dynamic>) {
      return body['deleted'] as bool? ?? false;
    }
    return false;
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
      throw SubflowsApiException(resp.statusCode, resp.body);
    }
  }
}
