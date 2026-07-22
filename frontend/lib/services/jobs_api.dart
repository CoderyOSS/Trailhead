import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_state.dart';

class JobDto {
  final String id;
  final String flowName;
  final String status;
  final String? description;
  final String startedAt;
  final String? finishedAt;
  final int nodeCount;

  /// YAML the job was launched with (snapshot stored by Carta at create
  /// time). Null for jobs created before snapshots existed.
  final String? content;

  const JobDto({
    required this.id,
    required this.flowName,
    required this.status,
    this.description,
    required this.startedAt,
    this.finishedAt,
    this.nodeCount = 0,
    this.content,
  });

  factory JobDto.fromJson(Map<String, dynamic> json) {
    return JobDto(
      id: json['id'] as String,
      flowName: json['flow_name'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      startedAt: json['started_at'] as String,
      finishedAt: json['finished_at'] as String?,
      nodeCount: (json['node_count'] as int?) ?? 0,
      content: json['content'] as String?,
    );
  }

  JobState get jobState =>
      status == 'running' ? JobState.running : JobState.cancelled;
}

class JobsApi {
  final String baseUrl;
  final http.Client client;

  JobsApi(this.baseUrl, [http.Client? client])
      : client = client ?? http.Client();

  /// Carta error bodies are `{"errors": [...]}` or `{"error": "..."}` — parse
  /// them into a readable message instead of showing raw JSON in snackbars.
  static String _errMsg(String fallback, String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['errors'] is List) {
        return (j['errors'] as List).join('; ');
      }
      if (j is Map && j['error'] != null) return '${j['error']}';
    } catch (_) {}
    return '$fallback: $body';
  }

  Future<List<JobDto>> list() async {
    final res = await client.get(Uri.parse('$baseUrl/jobs'));
    if (res.statusCode != 200) {
      throw Exception(_errMsg('list jobs failed', res.body));
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => JobDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<JobDto> create(String flowName, {String? description}) async {
    final body = <String, dynamic>{'flow_name': flowName};
    if (description != null) body['description'] = description;
    final res = await client.post(
      Uri.parse('$baseUrl/jobs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception(_errMsg('create job failed', res.body));
    }
    return JobDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<JobDto> cancel(String jobId) async {
    final res = await client.post(Uri.parse('$baseUrl/jobs/$jobId/cancel'));
    if (res.statusCode != 200) {
      throw Exception(_errMsg('cancel job failed', res.body));
    }
    return JobDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
