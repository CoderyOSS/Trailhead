import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/job_state.dart';
import 'package:frontend/providers/api_provider.dart';
import 'package:frontend/providers/carta_provider.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/jobs_api.dart';

class _FakeJobsApi implements JobsApi {
  _FakeJobsApi(this.returned);
  final JobDto returned;
  int cancelCalls = 0;

  @override
  Future<JobDto> cancel(String jobId) async {
    cancelCalls++;
    expect(jobId, 'j1');
    return returned;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

JobDto _job({required String id, JobState state = JobState.running}) {
  return JobDto(
    id: id,
    flowName: 'flow-$id',
    status: state == JobState.running ? 'running' : 'cancelled',
    startedAt: '2026-07-24T00:00:00Z',
  );
}

void main() {
  testWidgets('cancelJob clears selectedJobProvider and refreshes jobsProvider',
      (tester) async {
    final cancelled = _job(id: 'j1', state: JobState.cancelled);
    final fake = _FakeJobsApi(cancelled);

    final container = ProviderContainer(
      overrides: [
        jobsApiProvider.overrideWith((ref) => fake),
        jobsProvider.overrideWith((ref) async => [_job(id: 'j1')]),
      ],
    );
    addTearDown(container.dispose);

    // Seed a selected running job — the precondition for the bug.
    container.read(selectedJobProvider.notifier).state = _job(id: 'j1');
    expect(container.read(selectedJobProvider)?.id, 'j1');

    // Pump a trivial widget so a BuildContext / WidgetRef exists.
    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(builder: (c, r, _) {
            ref = r;
            return const SizedBox.shrink();
          }),
        ),
      ),
    );

    await cancelJob(ref, 'j1');

    expect(fake.cancelCalls, 1);
    expect(container.read(selectedJobProvider), isNull,
        reason: 'selection must be cleared so the empty-state hero renders');
  });
}
