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


