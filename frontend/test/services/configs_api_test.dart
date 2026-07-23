import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/configs_api.dart';

void main() {
  group('ConfigsApi', () {
    test('list decodes array of configs', () async {
      final api = ConfigsApi('/api/v1', client: MockClient((req) async {
        expect(req.method, 'GET');
        expect(req.url.path, '/api/v1/configs');
        return http.Response(
          jsonEncode([
            {'key': 'db', 'source': '%{x: 1}', 'updated_at': '2026-07-23T00:00:00Z'}
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }));
      final cfgs = await api.list();
      expect(cfgs.length, 1);
      expect(cfgs.first.key, 'db');
      expect(cfgs.first.source, '%{x: 1}');
      expect(cfgs.first.updatedAt, '2026-07-23T00:00:00Z');
    });

    test('get decodes a single config', () async {
      final api = ConfigsApi('/api/v1', client: MockClient((req) async {
        expect(req.url.path, '/api/v1/configs/db');
        return http.Response(
          jsonEncode({'key': 'db', 'source': '%{x: 1}', 'updated_at': '2026-07-23T00:00:00Z'}),
          200,
        );
      }));
      final cfg = await api.get('db');
      expect(cfg.key, 'db');
      expect(cfg.source, '%{x: 1}');
    });

    test('create POSTs key+source', () async {
      final api = ConfigsApi('/api/v1', client: MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/v1/configs');
        final body = jsonDecode(req.body);
        expect(body['key'], 'db');
        expect(body['source'], '%{x: 1}');
        return http.Response('', 201);
      }));
      await api.create('db', '%{x: 1}');
    });

    test('replace PUTs source', () async {
      final api = ConfigsApi('/api/v1', client: MockClient((req) async {
        expect(req.method, 'PUT');
        expect(req.url.path, '/api/v1/configs/db');
        final body = jsonDecode(req.body);
        expect(body['source'], '%{x: 2}');
        return http.Response('', 200);
      }));
      await api.replace('db', '%{x: 2}');
    });

    test('delete sends DELETE', () async {
      final api = ConfigsApi('/api/v1', client: MockClient((req) async {
        expect(req.method, 'DELETE');
        expect(req.url.path, '/api/v1/configs/db');
        return http.Response('', 204);
      }));
      await api.delete('db');
    });

    test('create throws on 409 conflict', () async {
      final api = ConfigsApi('/api/v1', client: MockClient((req) async {
        return http.Response(jsonEncode({'error': 'key_exists'}), 409);
      }));
      expect(() => api.create('db', '%{x: 1}'), throwsA(isA<ConfigsApiException>()));
    });

    test('get throws on 404', () async {
      final api = ConfigsApi('/api/v1', client: MockClient((req) async {
        return http.Response(jsonEncode({'error': 'not_found'}), 404);
      }));
      expect(() => api.get('missing'), throwsA(isA<ConfigsApiException>()));
    });
  });
}
