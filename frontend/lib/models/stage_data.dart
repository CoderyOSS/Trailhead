class SwitchCase {
  final String match;
  final List<String> to;

  const SwitchCase({required this.match, required this.to});

  SwitchCase copyWith({String? match, List<String>? to}) {
    return SwitchCase(match: match ?? this.match, to: to ?? this.to);
  }
}

class BranchCase {
  final String match;
  final List<String> to;
  final bool loop;

  const BranchCase({required this.match, required this.to, this.loop = false});

  BranchCase copyWith({String? match, List<String>? to, bool? loop}) {
    return BranchCase(
      match: match ?? this.match,
      to: to ?? this.to,
      loop: loop ?? this.loop,
    );
  }
}

class StageBody {
  final String label;
  final String? model;
  final List<String> skills;
  final String prompt;

  const StageBody({
    required this.label,
    this.model,
    this.skills = const [],
    required this.prompt,
  });

  StageBody copyWith({
    String? label,
    String? model,
    List<String>? skills,
    String? prompt,
  }) {
    return StageBody(
      label: label ?? this.label,
      model: model ?? this.model,
      skills: skills ?? this.skills,
      prompt: prompt ?? this.prompt,
    );
  }
}

class ToolCall {
  final String name;
  final String? args;
  final bool? ok;
  final bool running;
  final int ms;

  const ToolCall({
    required this.name,
    this.args,
    this.ok,
    this.running = false,
    this.ms = 0,
  });
}

class StageExecution {
  final String id;
  final String label;
  final String status; // passed, failed, running, retrying, queued, skipped
  final String? startedAt;
  final int durMs;
  final int tokens;
  final double? progress;
  final List<ToolCall>? tools;
  final String? renderedPrompt;
  final String? streaming;
  final dynamic result;
  final ({String code, String message})? error;
  final String? skipReason;
  final List<String>? waitsFor;

  const StageExecution({
    required this.id,
    required this.label,
    required this.status,
    this.startedAt,
    this.durMs = 0,
    this.tokens = 0,
    this.progress,
    this.tools,
    this.renderedPrompt,
    this.streaming,
    this.result,
    this.error,
    this.skipReason,
    this.waitsFor,
  });
}
