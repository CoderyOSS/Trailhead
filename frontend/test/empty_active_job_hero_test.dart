import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/job_state.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/jobs_api.dart';
import 'package:frontend/widgets/empty_active_job_hero.dart';

JobDto _job({required String id, JobState state = JobState.running}) {
  return JobDto(
    id: id,
    flowName: 'flow-$id',
    status: state == JobState.running ? 'running' : 'cancelled',
    startedAt: '2026-07-24T00:00:00Z',
  );
}

Widget _host(List<JobDto> jobs) {
  return ProviderScope(
    overrides: [
      jobsProvider.overrideWith((ref) async => jobs),
    ],
    child: MaterialApp(
      home: Scaffold(body: EmptyActiveJobHero()),
    ),
  );
}

void main() {
  testWidgets('no running jobs → "No active jobs" copy', (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.text('No active jobs'), findsOneWidget);
    expect(find.text('No job selected'), findsNothing);
    expect(
      find.textContaining('There are no running jobs to show'),
      findsOneWidget,
    );
  });

  testWidgets('running jobs exist but none picked → "No job selected" copy',
      (tester) async {
    await tester.pumpWidget(_host([_job(id: 'j1')]));
    await tester.pumpAndSettle();

    expect(find.text('No job selected'), findsOneWidget);
    expect(find.text('No active jobs'), findsNothing);
    expect(
      find.textContaining('Select a job from the dropdown'),
      findsOneWidget,
    );
  });

  testWidgets('only non-running jobs → treated as no active jobs',
      (tester) async {
    await tester.pumpWidget(
      _host([_job(id: 'j1', state: JobState.cancelled)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active jobs'), findsOneWidget);
    expect(find.text('No job selected'), findsNothing);
  });
}
