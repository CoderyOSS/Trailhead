import '../models/workflow_edge.dart';
import '../models/workflow_node.dart';

/// Shared validation for pipe/message connections.
///
/// Mirrors the Carta backend Phase 1 contracts (spec §4):
///   1. Each node is classified actor vs function (see `WorkflowNode.isActor`).
///   2. Connection type is inferred from the `to` node — never stored.
///   3. Max 1 pipe per `from` node (you can't pipe one value into two functions).
///   4. Messages: unlimited.
///   5. All `from`/`to` must reference declared nodes.
///
/// Used by both drag-drop (probe a candidate before committing) and paint-time
/// rendering (flag loaded connections that became invalid).
abstract final class ConnectionValidator {
  /// Node kinds that wrap an Erlang process. Mirrors
  /// `WorkflowNodeKind.actorKinds` — duplicated as a static here so tests can
  /// assert disjointness without instantiating a node.
  static const Set<String> actorKinds =
      WorkflowNodeKind.actorKinds;

  static const Set<String> functionKinds =
      WorkflowNodeKind.functionKinds;

  /// A connection is a pipe when its target is a function node (not an actor).
  /// Unknown targets return false (handled as invalid by [invalidIds]).
  static bool isPipe(
    WorkflowConnection c,
    Map<String, WorkflowNode> nodes,
  ) {
    final target = nodes[c.to];
    if (target == null) return false;
    return !target.isActor;
  }

  /// A connection is a message when its target is an actor node.
  static bool isMessage(
    WorkflowConnection c,
    Map<String, WorkflowNode> nodes,
  ) {
    final target = nodes[c.to];
    if (target == null) return false;
    return target.isActor;
  }

  /// Returns true if [candidate] can be added to [existing] without violating
  /// any rule. [existing] must NOT contain the candidate itself.
  ///
  /// Rules checked:
  ///   - both endpoints reference declared nodes
  ///   - target accepts input (`hasInput`) and source emits output (`hasOutput`)
  ///   - if target is a function (pipe): `from` has zero existing pipes
  ///   - if target is an actor  (message): always allowed (unlimited)
  static bool wouldBeValid(
    WorkflowConnection candidate,
    List<WorkflowConnection> existing,
    Map<String, WorkflowNode> nodes,
  ) {
    if (!nodes.containsKey(candidate.from) ||
        !nodes.containsKey(candidate.to)) {
      return false;
    }
    final source = nodes[candidate.from]!;
    final target = nodes[candidate.to]!;
    if (!source.hasOutput || !target.hasInput) return false;
    if (target.isActor) return true; // messages unlimited
    // Pipe: at most one per source.
    for (final c in existing) {
      if (c.from == candidate.from) {
        final existingTarget = nodes[c.to];
        if (existingTarget != null && !existingTarget.isActor) {
          return false;
        }
      }
    }
    return true;
  }

  /// Returns the IDs of connections that violate any rule, given the full set.
  ///
  /// Used at paint time to render broken connections in red. A connection is
  /// invalid when:
  ///   - `from` or `to` does not resolve to a declared node, OR
  ///   - it is a pipe and its source has more than one outgoing pipe.
  ///     (When a source over-pipes, ALL its pipes render red — the user sees
  ///     the broken state and decides which to delete.)
  static Set<String> invalidIds(
    List<WorkflowConnection> connections,
    Map<String, WorkflowNode> nodes,
  ) {
    // Count pipes per source (only counting connections whose endpoints resolve
    // and whose target is a function).
    final pipeCountPerSource = <String, int>{};
    for (final c in connections) {
      if (!nodes.containsKey(c.from) || !nodes.containsKey(c.to)) continue;
      final target = nodes[c.to]!;
      if (!target.isActor) {
        pipeCountPerSource[c.from] =
            (pipeCountPerSource[c.from] ?? 0) + 1;
      }
    }

    final invalid = <String>{};
    for (final c in connections) {
      if (!nodes.containsKey(c.from) || !nodes.containsKey(c.to)) {
        invalid.add(c.id);
        continue;
      }
      final source = nodes[c.from]!;
      final target = nodes[c.to]!;
      if (!source.hasOutput || !target.hasInput) {
        invalid.add(c.id);
        continue;
      }
      if (!target.isActor && (pipeCountPerSource[c.from] ?? 0) > 1) {
        invalid.add(c.id);
      }
    }
    return invalid;
  }
}
