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

  const JobDto({
    required this.id,
    required this.flowName,
    required this.status,
    this.description,
    required this.startedAt,
    this.finishedAt,
    this.nodeCount = 0,
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

  Future<List<JobDto>> list() async {
    final res = await client.get(Uri.parse('$baseUrl/jobs'));
    if (res.statusCode != 200) throw Exception('list jobs failed: ${res.body}');
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
    if (res.statusCode != 201) throw Exception('create job failed: ${res.body}');
    return JobDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<JobDto> cancel(String jobId) async {
    final res = await client.post(Uri.parse('$baseUrl/jobs/$jobId/cancel'));
    if (res.statusCode != 200) throw Exception('cancel job failed: ${res.body}');
    return JobDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
