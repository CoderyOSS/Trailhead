import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/workflow_edge.dart';
import 'package:frontend/models/workflow_node.dart';
import 'package:frontend/utils/connection_validator.dart';

WorkflowNode _node(String id, String kind, {double x = 0, double y = 0}) =>
    WorkflowNode(id: id, kind: kind, label: id, x: x, y: y);

WorkflowConnection _conn(String id, String from, String to, {int? sourcePort}) =>
    WorkflowConnection(id: id, from: from, to: to, sourcePort: sourcePort);

void main() {
  group('WorkflowNode classification', () {
    test('isActor is true for the 5 actor kinds', () {
      for (final kind in [
        'genserver',
        'http.server.ingress',
        'http.client.request',
        'task',
        'source.inject',
      ]) {
        expect(_node('n', kind).isActor, isTrue, reason: '$kind should be actor');
      }
    });

    test('isFunction is true for the 4 function kinds', () {
      for (final kind in ['function', 'delay', 'sink.log', 'http.server.egress']) {
        expect(_node('n', kind).isFunction, isTrue,
            reason: '$kind should be function');
      }
    });

    test('actor kinds and function kinds are disjoint', () {
      final actors = WorkflowNodeKind.actorKinds;
      final functions = WorkflowNodeKind.functionKinds;
      expect(actors.intersection(functions), isEmpty);
    });

    test('legacy canvas kinds (worker, fan, branch) are neither', () {
      final n = _node('n', 'worker');
      expect(n.isActor, isFalse);
      expect(n.isFunction, isFalse);
    });
  });

  group('ConnectionValidator.isPipe / isMessage', () {
    final nodes = {
      'a': _node('a', 'function'),
      'b': _node('b', 'genserver'),
    };

    test('connection to a function is a pipe', () {
      expect(ConnectionValidator.isPipe(_conn('1', 'src', 'a'), nodes), isTrue);
    });

    test('connection to an actor is a message', () {
      expect(ConnectionValidator.isMessage(_conn('1', 'src', 'b'), nodes),
          isTrue);
    });

    test('pipe and message are mutually exclusive', () {
      final c = _conn('1', 'src', 'a');
      expect(ConnectionValidator.isPipe(c, nodes),
          !ConnectionValidator.isMessage(c, nodes));
    });

    test('unknown target is neither pipe nor message', () {
      final c = _conn('1', 'src', 'missing');
      expect(ConnectionValidator.isPipe(c, nodes), isFalse);
      expect(ConnectionValidator.isMessage(c, nodes), isFalse);
    });
  });

  group('ConnectionValidator.wouldBeValid (drag-drop candidate)', () {
    final nodes = {
      'src': _node('src', 'source.inject'),
      'fn1': _node('fn1', 'function'),
      'fn2': _node('fn2', 'delay'),
      'actor1': _node('actor1', 'genserver'),
      'actor2': _node('actor2', 'task'),
    };

    test('valid: first pipe from a source', () {
      expect(
        ConnectionValidator.wouldBeValid(
          _conn('new', 'src', 'fn1'),
          const [],
          nodes,
        ),
        isTrue,
      );
    });

    test('invalid: second pipe from same source to a different function', () {
      final existing = [_conn('e1', 'src', 'fn1')];
      expect(
        ConnectionValidator.wouldBeValid(
          _conn('new', 'src', 'fn2'),
          existing,
          nodes,
        ),
        isFalse,
      );
    });

    test('valid: unlimited messages from same source to actors', () {
      final existing = [
        _conn('e1', 'src', 'actor1'),
        _conn('e2', 'src', 'actor2'),
      ];
      expect(
        ConnectionValidator.wouldBeValid(
          _conn('new', 'src', 'actor1'),
          existing,
          nodes,
        ),
        isTrue,
      );
    });

    test('valid: mixed — one pipe plus many messages from same source', () {
      final existing = [
        _conn('e1', 'src', 'fn1'),
        _conn('e2', 'src', 'actor1'),
      ];
      expect(
        ConnectionValidator.wouldBeValid(
          _conn('new', 'src', 'actor2'),
          existing,
          nodes,
        ),
        isTrue,
      );
    });

    test('invalid: unknown from node', () {
      expect(
        ConnectionValidator.wouldBeValid(
          _conn('new', 'ghost', 'fn1'),
          const [],
          nodes,
        ),
        isFalse,
      );
    });

    test('invalid: unknown to node', () {
      expect(
        ConnectionValidator.wouldBeValid(
          _conn('new', 'src', 'ghost'),
          const [],
          nodes,
        ),
        isFalse,
      );
    });
  });

  group('ConnectionValidator.invalidIds (paint-time rendering)', () {
    final nodes = {
      'src': _node('src', 'source.inject'),
      'fn1': _node('fn1', 'function'),
      'fn2': _node('fn2', 'delay'),
      'actor': _node('actor', 'genserver'),
    };

    test('all connections valid → empty set', () {
      final conns = [
        _conn('c1', 'src', 'fn1'),
        _conn('c2', 'src', 'actor'),
      ];
      expect(ConnectionValidator.invalidIds(conns, nodes), isEmpty);
    });

    test('two pipes from same source → both invalid', () {
      final conns = [
        _conn('c1', 'src', 'fn1'),
        _conn('c2', 'src', 'fn2'),
      ];
      final invalid = ConnectionValidator.invalidIds(conns, nodes);
      expect(invalid, {'c1', 'c2'});
    });

    test('messages alongside over-piped source stay valid', () {
      final conns = [
        _conn('c1', 'src', 'fn1'),
        _conn('c2', 'src', 'fn2'),
        _conn('c3', 'src', 'actor'),
      ];
      final invalid = ConnectionValidator.invalidIds(conns, nodes);
      expect(invalid, {'c1', 'c2'});
      expect(invalid.contains('c3'), isFalse);
    });

    test('dangling reference → invalid', () {
      final conns = [_conn('c1', 'src', 'ghost')];
      expect(ConnectionValidator.invalidIds(conns, nodes), {'c1'});
    });
  });
}
