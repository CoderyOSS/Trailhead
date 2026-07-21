import '../services/thrt_api.dart';
import '../widgets/icons.dart';

class NodeEntry {
  final String kind;
  final String label;
  final String desc;
  final TrailheadIconData icon;
  final String? docsUrl;
  final String? templateExpr;

  const NodeEntry({
    required this.kind,
    required this.label,
    required this.desc,
    required this.icon,
    this.docsUrl,
    this.templateExpr,
  });

  bool get isTransform => templateExpr != null;
}

class NodeCategory {
  final String label;
  final List<NodeEntry> entries;

  const NodeCategory({required this.label, required this.entries});
}

const _e = 'https://hexdocs.pm/elixir/1.14';

String _doc(String module, String func, int arity) {
  final an = arity.toString();
  return '$_e/$module.html#$func/$an';
}

String _e0(String call) => '$call()';
String _e1(String call) => '$call(payload)';
String _e2(String call) => '$call(payload, _)';
String _e3(String call) => '$call(payload, _, _)';

const _zap = TrailheadIconData.zap;
const _stopwatch = TrailheadIconData.stopwatch;
const _globe = TrailheadIconData.globe;
const _branch = TrailheadIconData.gitBranch;
const _play = TrailheadIconData.play;
const _terminal = TrailheadIconData.terminal;

/// Dynamic picker category for modules installed in the connected runtime
/// (builtins already in [nodeCategories] are skipped). Returns null when
/// nothing new is installed.
NodeCategory? installedModulesCategory(List<InstalledNode> nodes) {
  const builtinKinds = {
    'genserver',
    'task',
    'source.inject',
    'http.server.ingress',
    'http.client.request',
    'function',
    'delay',
    'http.server.egress',
    'subflow',
  };
  final entries = nodes
      .where((n) => !builtinKinds.contains(n.type))
      .map((n) => NodeEntry(kind: n.type, label: n.label, desc: n.desc, icon: _zap))
      .toList();
  if (entries.isEmpty) return null;
  return NodeCategory(label: 'INSTALLED MODULES', entries: entries);
}

/// Static picker category for the `subflow` pseudo-builtin. Sits between
/// ACTORS and INSTALLED MODULES so it's discoverable.
const subflowCategory = NodeCategory(label: 'COMPOSE', entries: [
  NodeEntry(
    kind: 'subflow',
    label: 'subflow',
    desc: 'embed a reusable flow as a node (params resolved at deploy)',
    icon: TrailheadIconData.workflow,
  ),
]);

final List<NodeCategory> nodeCategories = [
  NodeCategory(label: 'ACTORS', entries: [
    const NodeEntry(kind: 'genserver', label: 'genserver', desc: 'stateful \u00b7 module or inline', icon: _zap),
    const NodeEntry(kind: 'task', label: 'task', desc: 'stateless \u00b7 concurrent \u00b7 elixir expr', icon: _zap),
    const NodeEntry(kind: 'source.inject', label: 'source.inject', desc: 'timer or one-shot inject', icon: _play),
    const NodeEntry(kind: 'http.server.ingress', label: 'http server ingress', desc: 'HTTP server endpoint', icon: _globe),
    const NodeEntry(kind: 'http.client.request', label: 'http client request', desc: 'Outbound HTTP call', icon: _globe),
  ]),
  NodeCategory(label: 'FUNCTIONS', entries: [
    const NodeEntry(kind: 'function', label: 'function', desc: 'conditional routing', icon: _branch),
    const NodeEntry(kind: 'function', label: 'transform', desc: 'custom Elixir expr — full Kernel/Map/Access', icon: _terminal, templateExpr: 'payload'),
    const NodeEntry(kind: 'delay', label: 'delay', desc: 'timed delay  configurable ms', icon: _stopwatch),
    const NodeEntry(kind: 'http.server.egress', label: 'http server egress', desc: 'HTTP response', icon: _globe),
  ]),
  NodeCategory(label: 'Elixir.String', entries: [
    NodeEntry(kind: 'function', label: 'String.length/1', desc: 'Returns the number of graphemes', icon: _terminal, docsUrl: _doc('String', 'length', 1), templateExpr: _e1('String.length')),
    NodeEntry(kind: 'function', label: 'String.downcase/1', desc: 'Converts to lowercase', icon: _terminal, docsUrl: _doc('String', 'downcase', 1), templateExpr: _e1('String.downcase')),
    NodeEntry(kind: 'function', label: 'String.upcase/1', desc: 'Converts to uppercase', icon: _terminal, docsUrl: _doc('String', 'upcase', 1), templateExpr: _e1('String.upcase')),
    NodeEntry(kind: 'function', label: 'String.trim/1', desc: 'Removes leading/trailing whitespace', icon: _terminal, docsUrl: _doc('String', 'trim', 1), templateExpr: _e1('String.trim')),
    NodeEntry(kind: 'function', label: 'String.trim_leading/1', desc: 'Removes leading whitespace', icon: _terminal, docsUrl: _doc('String', 'trim_leading', 1), templateExpr: _e1('String.trim_leading')),
    NodeEntry(kind: 'function', label: 'String.trim_trailing/1', desc: 'Removes trailing whitespace', icon: _terminal, docsUrl: _doc('String', 'trim_trailing', 1), templateExpr: _e1('String.trim_trailing')),
    NodeEntry(kind: 'function', label: 'String.split/1', desc: 'Splits string on runs of whitespace', icon: _terminal, docsUrl: _doc('String', 'split', 1), templateExpr: _e1('String.split')),
    NodeEntry(kind: 'function', label: 'String.split/2', desc: 'Splits string on given pattern', icon: _terminal, docsUrl: _doc('String', 'split', 2), templateExpr: _e2('String.split')),
    NodeEntry(kind: 'function', label: 'String.replace/3', desc: 'Replaces pattern with replacement', icon: _terminal, docsUrl: _doc('String', 'replace', 3), templateExpr: _e3('String.replace')),
    NodeEntry(kind: 'function', label: 'String.replace/4', desc: 'Replaces pattern globally (global: true)', icon: _terminal, docsUrl: _doc('String', 'replace', 4), templateExpr: 'String.replace(payload, _, _, global: true)'),
    NodeEntry(kind: 'function', label: 'String.reverse/1', desc: 'Reverses graphemes', icon: _terminal, docsUrl: _doc('String', 'reverse', 1), templateExpr: _e1('String.reverse')),
    NodeEntry(kind: 'function', label: 'String.slice/2', desc: 'Slices string at given range', icon: _terminal, docsUrl: _doc('String', 'slice', 2), templateExpr: _e2('String.slice')),
    NodeEntry(kind: 'function', label: 'String.starts_with?/2', desc: 'Checks prefix match', icon: _terminal, docsUrl: _doc('String', 'starts_with?', 2), templateExpr: _e2('String.starts_with?')),
    NodeEntry(kind: 'function', label: 'String.ends_with?/2', desc: 'Checks suffix match', icon: _terminal, docsUrl: _doc('String', 'ends_with?', 2), templateExpr: _e2('String.ends_with?')),
    NodeEntry(kind: 'function', label: 'String.contains?/2', desc: 'Checks substring membership', icon: _terminal, docsUrl: _doc('String', 'contains?', 2), templateExpr: _e2('String.contains?')),
    NodeEntry(kind: 'function', label: 'String.capitalize/1', desc: 'Capitalizes first character', icon: _terminal, docsUrl: _doc('String', 'capitalize', 1), templateExpr: _e1('String.capitalize')),
    NodeEntry(kind: 'function', label: 'String.pad_leading/2', desc: 'Pads left to given length', icon: _terminal, docsUrl: _doc('String', 'pad_leading', 2), templateExpr: _e2('String.pad_leading')),
    NodeEntry(kind: 'function', label: 'String.pad_trailing/2', desc: 'Pads right to given length', icon: _terminal, docsUrl: _doc('String', 'pad_trailing', 2), templateExpr: _e2('String.pad_trailing')),
    NodeEntry(kind: 'function', label: 'String.duplicate/2', desc: 'Duplicates string n times', icon: _terminal, docsUrl: _doc('String', 'duplicate', 2), templateExpr: _e2('String.duplicate')),
    NodeEntry(kind: 'function', label: 'String.to_integer/1', desc: 'Parses to integer, returns tuple', icon: _terminal, docsUrl: _doc('String', 'to_integer', 1), templateExpr: _e1('String.to_integer')),
    NodeEntry(kind: 'function', label: 'String.to_atom/1', desc: 'Converts static string to atom', icon: _terminal, docsUrl: _doc('String', 'to_atom', 1), templateExpr: _e1('String.to_atom')),
  ]),
  NodeCategory(label: 'Elixir.Map', entries: [
    NodeEntry(kind: 'function', label: 'Map.get/2', desc: 'Gets value by key, nil if missing', icon: _terminal, docsUrl: _doc('Map', 'get', 2), templateExpr: _e2('Map.get')),
    NodeEntry(kind: 'function', label: 'Map.get/3', desc: 'Gets value by key with default', icon: _terminal, docsUrl: _doc('Map', 'get', 3), templateExpr: _e3('Map.get')),
    NodeEntry(kind: 'function', label: 'Map.put/3', desc: 'Puts key/value into map', icon: _terminal, docsUrl: _doc('Map', 'put', 3), templateExpr: _e3('Map.put')),
    NodeEntry(kind: 'function', label: 'Map.delete/2', desc: 'Removes key from map', icon: _terminal, docsUrl: _doc('Map', 'delete', 2), templateExpr: _e2('Map.delete')),
    NodeEntry(kind: 'function', label: 'Map.has_key?/2', desc: 'Checks if key exists', icon: _terminal, docsUrl: _doc('Map', 'has_key?', 2), templateExpr: _e2('Map.has_key?')),
    NodeEntry(kind: 'function', label: 'Map.keys/1', desc: 'Returns list of all keys', icon: _terminal, docsUrl: _doc('Map', 'keys', 1), templateExpr: _e1('Map.keys')),
    NodeEntry(kind: 'function', label: 'Map.values/1', desc: 'Returns list of all values', icon: _terminal, docsUrl: _doc('Map', 'values', 1), templateExpr: _e1('Map.values')),
    NodeEntry(kind: 'function', label: 'Map.merge/2', desc: 'Merges two maps, right wins', icon: _terminal, docsUrl: _doc('Map', 'merge', 2), templateExpr: _e2('Map.merge')),
    NodeEntry(kind: 'function', label: 'Map.drop/2', desc: 'Drops given keys from map', icon: _terminal, docsUrl: _doc('Map', 'drop', 2), templateExpr: _e2('Map.drop')),
    NodeEntry(kind: 'function', label: 'Map.take/2', desc: 'Keeps only given keys', icon: _terminal, docsUrl: _doc('Map', 'take', 2), templateExpr: _e2('Map.take')),
    NodeEntry(kind: 'function', label: 'Map.pop/2', desc: 'Removes key, returns {v, map}', icon: _terminal, docsUrl: _doc('Map', 'pop', 2), templateExpr: _e2('Map.pop')),
    NodeEntry(kind: 'function', label: 'Map.pop/3', desc: 'Removes key with default', icon: _terminal, docsUrl: _doc('Map', 'pop', 3), templateExpr: _e3('Map.pop')),
    NodeEntry(kind: 'function', label: 'Map.fetch/2', desc: 'Fetches key, returns {:ok, v} or :error', icon: _terminal, docsUrl: _doc('Map', 'fetch', 2), templateExpr: _e2('Map.fetch')),
    NodeEntry(kind: 'function', label: 'Map.fetch!/2', desc: 'Fetches key, raises on missing', icon: _terminal, docsUrl: _doc('Map', 'fetch!', 2), templateExpr: _e2('Map.fetch!')),
    NodeEntry(kind: 'function', label: 'Map.put_new/3', desc: 'Puts key only if missing', icon: _terminal, docsUrl: _doc('Map', 'put_new', 3), templateExpr: _e3('Map.put_new')),
    NodeEntry(kind: 'function', label: 'Map.to_list/1', desc: 'Converts to keyword list', icon: _terminal, docsUrl: _doc('Map', 'to_list', 1), templateExpr: _e1('Map.to_list')),
    NodeEntry(kind: 'function', label: 'Map.from_enum/1', desc: 'Creates map from enum of tuples', icon: _terminal, docsUrl: _doc('Map', 'from_enum', 1), templateExpr: _e1('Map.from_enum')),
  ]),
  NodeCategory(label: 'Elixir.Enum', entries: [
    NodeEntry(kind: 'function', label: 'Enum.map/2', desc: 'Transforms each element', icon: _terminal, docsUrl: _doc('Enum', 'map', 2), templateExpr: _e2('Enum.map')),
    NodeEntry(kind: 'function', label: 'Enum.filter/2', desc: 'Filters by truthy function', icon: _terminal, docsUrl: _doc('Enum', 'filter', 2), templateExpr: _e2('Enum.filter')),
    NodeEntry(kind: 'function', label: 'Enum.reduce/3', desc: 'Reduces with accumulator', icon: _terminal, docsUrl: _doc('Enum', 'reduce', 3), templateExpr: _e3('Enum.reduce')),
    NodeEntry(kind: 'function', label: 'Enum.each/2', desc: 'Iterates for side effects', icon: _terminal, docsUrl: _doc('Enum', 'each', 2), templateExpr: _e2('Enum.each')),
    NodeEntry(kind: 'function', label: 'Enum.sort/1', desc: 'Sorts elements', icon: _terminal, docsUrl: _doc('Enum', 'sort', 1), templateExpr: _e1('Enum.sort')),
    NodeEntry(kind: 'function', label: 'Enum.sort/2', desc: 'Sorts elements with comparator', icon: _terminal, docsUrl: _doc('Enum', 'sort', 2), templateExpr: _e2('Enum.sort')),
    NodeEntry(kind: 'function', label: 'Enum.sort_by/3', desc: 'Sorts by mapped value', icon: _terminal, docsUrl: _doc('Enum', 'sort_by', 3), templateExpr: _e3('Enum.sort_by')),
    NodeEntry(kind: 'function', label: 'Enum.reverse/1', desc: 'Reverses list order', icon: _terminal, docsUrl: _doc('Enum', 'reverse', 1), templateExpr: _e1('Enum.reverse')),
    NodeEntry(kind: 'function', label: 'Enum.uniq/1', desc: 'Removes duplicates', icon: _terminal, docsUrl: _doc('Enum', 'uniq', 1), templateExpr: _e1('Enum.uniq')),
    NodeEntry(kind: 'function', label: 'Enum.count/1', desc: 'Counts elements', icon: _terminal, docsUrl: _doc('Enum', 'count', 1), templateExpr: _e1('Enum.count')),
    NodeEntry(kind: 'function', label: 'Enum.join/2', desc: 'Joins elements with separator', icon: _terminal, docsUrl: _doc('Enum', 'join', 2), templateExpr: _e2('Enum.join')),
    NodeEntry(kind: 'function', label: 'Enum.chunk_every/2', desc: 'Chunks into slices of n', icon: _terminal, docsUrl: _doc('Enum', 'chunk_every', 2), templateExpr: _e2('Enum.chunk_every')),
    NodeEntry(kind: 'function', label: 'Enum.find/2', desc: 'Finds first matching element', icon: _terminal, docsUrl: _doc('Enum', 'find', 2), templateExpr: _e2('Enum.find')),
    NodeEntry(kind: 'function', label: 'Enum.any?/2', desc: 'Checks if any match predicate', icon: _terminal, docsUrl: _doc('Enum', 'any?', 2), templateExpr: _e2('Enum.any?')),
    NodeEntry(kind: 'function', label: 'Enum.all?/2', desc: 'Checks if all match predicate', icon: _terminal, docsUrl: _doc('Enum', 'all?', 2), templateExpr: _e2('Enum.all?')),
    NodeEntry(kind: 'function', label: 'Enum.at/2', desc: 'Gets element at index', icon: _terminal, docsUrl: _doc('Enum', 'at', 2), templateExpr: _e2('Enum.at')),
    NodeEntry(kind: 'function', label: 'Enum.into/2', desc: 'Inserts into collectable', icon: _terminal, docsUrl: _doc('Enum', 'into', 2), templateExpr: _e2('Enum.into')),
    NodeEntry(kind: 'function', label: 'Enum.sum/1', desc: 'Sums all elements', icon: _terminal, docsUrl: _doc('Enum', 'sum', 1), templateExpr: _e1('Enum.sum')),
    NodeEntry(kind: 'function', label: 'Enum.min/1', desc: 'Returns minimum value', icon: _terminal, docsUrl: _doc('Enum', 'min', 1), templateExpr: _e1('Enum.min')),
    NodeEntry(kind: 'function', label: 'Enum.max/1', desc: 'Returns maximum value', icon: _terminal, docsUrl: _doc('Enum', 'max', 1), templateExpr: _e1('Enum.max')),
    NodeEntry(kind: 'function', label: 'Enum.group_by/2', desc: 'Groups by classifier function', icon: _terminal, docsUrl: _doc('Enum', 'group_by', 2), templateExpr: _e2('Enum.group_by')),
    NodeEntry(kind: 'function', label: 'Enum.map_join/3', desc: 'Maps and joins in one pass', icon: _terminal, docsUrl: _doc('Enum', 'map_join', 3), templateExpr: _e3('Enum.map_join')),
  ]),
  NodeCategory(label: 'Elixir.List', entries: [
    NodeEntry(kind: 'function', label: 'List.first/1', desc: 'Returns first ele, nil on empty', icon: _terminal, docsUrl: _doc('List', 'first', 1), templateExpr: _e1('List.first')),
    NodeEntry(kind: 'function', label: 'List.last/1', desc: 'Returns last ele, nil on empty', icon: _terminal, docsUrl: _doc('List', 'last', 1), templateExpr: _e1('List.last')),
    NodeEntry(kind: 'function', label: 'List.delete/2', desc: 'Removes first occurrence', icon: _terminal, docsUrl: _doc('List', 'delete', 2), templateExpr: _e2('List.delete')),
    NodeEntry(kind: 'function', label: 'List.wrap/1', desc: 'Wraps value in list if not a list', icon: _terminal, docsUrl: _doc('List', 'wrap', 1), templateExpr: _e1('List.wrap')),
    NodeEntry(kind: 'function', label: 'List.flatten/1', desc: 'Flattens nested lists', icon: _terminal, docsUrl: _doc('List', 'flatten', 1), templateExpr: _e1('List.flatten')),
    NodeEntry(kind: 'function', label: 'List.foldl/3', desc: 'Left fold with accumulator', icon: _terminal, docsUrl: _doc('List', 'foldl', 3), templateExpr: _e3('List.foldl')),
    NodeEntry(kind: 'function', label: 'List.foldr/3', desc: 'Right fold with accumulator', icon: _terminal, docsUrl: _doc('List', 'foldr', 3), templateExpr: _e3('List.foldr')),
    NodeEntry(kind: 'function', label: 'List.keyfind/3', desc: 'Finds tuple by key index', icon: _terminal, docsUrl: _doc('List', 'keyfind', 3), templateExpr: _e3('List.keyfind')),
    NodeEntry(kind: 'function', label: 'List.keymember?/3', desc: 'Checks tuple key membership', icon: _terminal, docsUrl: _doc('List', 'keymember?', 3), templateExpr: _e3('List.keymember?')),
  ]),
  NodeCategory(label: 'Elixir.Keyword', entries: [
    NodeEntry(kind: 'function', label: 'Keyword.get/2', desc: 'Gets value by key', icon: _terminal, docsUrl: _doc('Keyword', 'get', 2), templateExpr: _e2('Keyword.get')),
    NodeEntry(kind: 'function', label: 'Keyword.get/3', desc: 'Gets value with default', icon: _terminal, docsUrl: _doc('Keyword', 'get', 3), templateExpr: _e3('Keyword.get')),
    NodeEntry(kind: 'function', label: 'Keyword.put/3', desc: 'Puts or replaces value', icon: _terminal, docsUrl: _doc('Keyword', 'put', 3), templateExpr: _e3('Keyword.put')),
    NodeEntry(kind: 'function', label: 'Keyword.delete/2', desc: 'Removes entry by key', icon: _terminal, docsUrl: _doc('Keyword', 'delete', 2), templateExpr: _e2('Keyword.delete')),
    NodeEntry(kind: 'function', label: 'Keyword.has_key?/2', desc: 'Checks key existence', icon: _terminal, docsUrl: _doc('Keyword', 'has_key?', 2), templateExpr: _e2('Keyword.has_key?')),
    NodeEntry(kind: 'function', label: 'Keyword.keys/1', desc: 'Returns all keys', icon: _terminal, docsUrl: _doc('Keyword', 'keys', 1), templateExpr: _e1('Keyword.keys')),
    NodeEntry(kind: 'function', label: 'Keyword.values/1', desc: 'Returns all values', icon: _terminal, docsUrl: _doc('Keyword', 'values', 1), templateExpr: _e1('Keyword.values')),
    NodeEntry(kind: 'function', label: 'Keyword.pop/3', desc: 'Removes key, returns {v, kw}', icon: _terminal, docsUrl: _doc('Keyword', 'pop', 3), templateExpr: _e3('Keyword.pop')),
    NodeEntry(kind: 'function', label: 'Keyword.take/2', desc: 'Keeps only given keys', icon: _terminal, docsUrl: _doc('Keyword', 'take', 2), templateExpr: _e2('Keyword.take')),
    NodeEntry(kind: 'function', label: 'Keyword.drop/2', desc: 'Drops given keys', icon: _terminal, docsUrl: _doc('Keyword', 'drop', 2), templateExpr: _e2('Keyword.drop')),
  ]),
  NodeCategory(label: 'Elixir.DateTime', entries: [
    NodeEntry(kind: 'function', label: 'DateTime.utc_now/0', desc: 'Current UTC datetime', icon: _terminal, docsUrl: _doc('DateTime', 'utc_now', 0), templateExpr: _e0('DateTime.utc_now')),
    NodeEntry(kind: 'function', label: 'DateTime.now/1', desc: 'Current datetime in timezone', icon: _terminal, docsUrl: _doc('DateTime', 'now', 1), templateExpr: _e1('DateTime.now')),
    NodeEntry(kind: 'function', label: 'DateTime.to_date/1', desc: 'Extracts Date from DateTime', icon: _terminal, docsUrl: _doc('DateTime', 'to_date', 1), templateExpr: _e1('DateTime.to_date')),
    NodeEntry(kind: 'function', label: 'DateTime.to_time/1', desc: 'Extracts Time from DateTime', icon: _terminal, docsUrl: _doc('DateTime', 'to_time', 1), templateExpr: _e1('DateTime.to_time')),
    NodeEntry(kind: 'function', label: 'DateTime.diff/2', desc: 'Difference in microseconds', icon: _terminal, docsUrl: _doc('DateTime', 'diff', 2), templateExpr: _e2('DateTime.diff')),
    NodeEntry(kind: 'function', label: 'DateTime.diff/3', desc: 'Difference in given unit (second, millisecond)', icon: _terminal, docsUrl: _doc('DateTime', 'diff', 3), templateExpr: _e3('DateTime.diff')),
    NodeEntry(kind: 'function', label: 'DateTime.compare/2', desc: 'Compares two datetimes', icon: _terminal, docsUrl: _doc('DateTime', 'compare', 2), templateExpr: _e2('DateTime.compare')),
    NodeEntry(kind: 'function', label: 'DateTime.add/4', desc: 'Adds duration in given unit', icon: _terminal, docsUrl: _doc('DateTime', 'add', 4), templateExpr: 'DateTime.add(payload, _, _, _)'),
  ]),
  NodeCategory(label: 'Elixir.Integer', entries: [
    NodeEntry(kind: 'function', label: 'Integer.parse/1', desc: 'Parses string to int (prefix only)', icon: _terminal, docsUrl: _doc('Integer', 'parse', 1), templateExpr: _e1('Integer.parse')),
    NodeEntry(kind: 'function', label: 'Integer.is_even/1', desc: 'Checks if even', icon: _terminal, docsUrl: _doc('Integer', 'is_even', 1), templateExpr: _e1('Integer.is_even')),
    NodeEntry(kind: 'function', label: 'Integer.is_odd/1', desc: 'Checks if odd', icon: _terminal, docsUrl: _doc('Integer', 'is_odd', 1), templateExpr: _e1('Integer.is_odd')),
    NodeEntry(kind: 'function', label: 'Integer.gcd/2', desc: 'Greates common divisor', icon: _terminal, docsUrl: _doc('Integer', 'gcd', 2), templateExpr: _e2('Integer.gcd')),
    NodeEntry(kind: 'function', label: 'Integer.digits/1', desc: 'Splits int into decimal digits', icon: _terminal, docsUrl: _doc('Integer', 'digits', 1), templateExpr: _e1('Integer.digits')),
    NodeEntry(kind: 'function', label: 'Integer.undigits/1', desc: 'Combines decimal digits into int', icon: _terminal, docsUrl: _doc('Integer', 'undigits', 1), templateExpr: _e1('Integer.undigits')),
  ]),
  NodeCategory(label: 'Elixir.Float', entries: [
    NodeEntry(kind: 'function', label: 'Float.ceil/1', desc: 'Rounds up to nearest int', icon: _terminal, docsUrl: _doc('Float', 'ceil', 1), templateExpr: _e1('Float.ceil')),
    NodeEntry(kind: 'function', label: 'Float.floor/1', desc: 'Rounds down to nearest int', icon: _terminal, docsUrl: _doc('Float', 'floor', 1), templateExpr: _e1('Float.floor')),
    NodeEntry(kind: 'function', label: 'Float.round/1', desc: 'Rounds to nearest int', icon: _terminal, docsUrl: _doc('Float', 'round', 1), templateExpr: _e1('Float.round')),
    NodeEntry(kind: 'function', label: 'Float.round/2', desc: 'Rounds to given decimal places', icon: _terminal, docsUrl: _doc('Float', 'round', 2), templateExpr: _e2('Float.round')),
    NodeEntry(kind: 'function', label: 'Float.parse/1', desc: 'Parses string to float (prefix only)', icon: _terminal, docsUrl: _doc('Float', 'parse', 1), templateExpr: _e1('Float.parse')),
  ]),
  NodeCategory(label: 'Elixir.Tuple', entries: [
    NodeEntry(kind: 'function', label: 'Tuple.duplicate/2', desc: 'Creates tuple of n copies', icon: _terminal, docsUrl: _doc('Tuple', 'duplicate', 2), templateExpr: _e2('Tuple.duplicate')),
    NodeEntry(kind: 'function', label: 'Tuple.insert_at/3', desc: 'Inserts value at index', icon: _terminal, docsUrl: _doc('Tuple', 'insert_at', 3), templateExpr: _e3('Tuple.insert_at')),
    NodeEntry(kind: 'function', label: 'Tuple.append/2', desc: 'Appends value to end of tuple', icon: _terminal, docsUrl: _doc('Tuple', 'append', 2), templateExpr: _e2('Tuple.append')),
    NodeEntry(kind: 'function', label: 'Tuple.delete_at/2', desc: 'Removes element at index', icon: _terminal, docsUrl: _doc('Tuple', 'delete_at', 2), templateExpr: _e2('Tuple.delete_at')),
  ]),
  NodeCategory(label: 'Elixir.Atom', entries: [
    NodeEntry(kind: 'function', label: 'Atom.to_string/1', desc: 'Converts atom to string', icon: _terminal, docsUrl: _doc('Atom', 'to_string', 1), templateExpr: _e1('Atom.to_string')),
    NodeEntry(kind: 'function', label: 'Atom.from_string/1', desc: 'Converts string to atom', icon: _terminal, docsUrl: _doc('Atom', 'from_string', 1), templateExpr: _e1('Atom.from_string')),
  ]),
  NodeCategory(label: 'Elixir.Regex', entries: [
    NodeEntry(kind: 'function', label: 'Regex.match?/2', desc: 'Checks if regex matches string', icon: _terminal, docsUrl: _doc('Regex', 'match?', 2), templateExpr: _e2('Regex.match?')),
    NodeEntry(kind: 'function', label: 'Regex.run/2', desc: 'Returns first match or nil', icon: _terminal, docsUrl: _doc('Regex', 'run', 2), templateExpr: _e2('Regex.run')),
    NodeEntry(kind: 'function', label: 'Regex.scan/2', desc: 'Returns all matches as list', icon: _terminal, docsUrl: _doc('Regex', 'scan', 2), templateExpr: _e2('Regex.scan')),
    NodeEntry(kind: 'function', label: 'Regex.replace/4', desc: 'Replaces all regex matches', icon: _terminal, docsUrl: _doc('Regex', 'replace', 4), templateExpr: 'Regex.replace(_, _, payload, _)'),
    NodeEntry(kind: 'function', label: 'Regex.split/3', desc: 'Splits string on regex match', icon: _terminal, docsUrl: _doc('Regex', 'split', 3), templateExpr: _e3('Regex.split')),
  ]),
  NodeCategory(label: 'Elixir.Kernel', entries: [
    NodeEntry(kind: 'function', label: 'Kernel.put_in/3', desc: 'Puts value at an Access path (payload[:key])', icon: _terminal, docsUrl: _doc('Kernel', 'put_in', 3), templateExpr: 'put_in(payload[:key], _)'),
    NodeEntry(kind: 'function', label: 'Kernel.update_in/3', desc: 'Updates value at an Access path via capture', icon: _terminal, docsUrl: _doc('Kernel', 'update_in', 3), templateExpr: 'update_in(payload[:key], &(&1))'),
    NodeEntry(kind: 'function', label: 'Kernel.get_in/2', desc: 'Gets value at a key list or Access path', icon: _terminal, docsUrl: _doc('Kernel', 'get_in', 2), templateExpr: 'get_in(payload, [:key])'),
    NodeEntry(kind: 'function', label: 'Kernel.is_nil/1', desc: 'Checks if value is nil', icon: _terminal, docsUrl: _doc('Kernel', 'is_nil', 1), templateExpr: _e1('is_nil')),
    NodeEntry(kind: 'function', label: 'Kernel.abs/1', desc: 'Returns absolute value', icon: _terminal, docsUrl: _doc('Kernel', 'abs', 1), templateExpr: _e1('abs')),
    NodeEntry(kind: 'function', label: 'Kernel.div/2', desc: 'Integer division', icon: _terminal, docsUrl: _doc('Kernel', 'div', 2), templateExpr: _e2('div')),
    NodeEntry(kind: 'function', label: 'Kernel.rem/2', desc: 'Remainder of integer division', icon: _terminal, docsUrl: _doc('Kernel', 'rem', 2), templateExpr: _e2('rem')),
    NodeEntry(kind: 'function', label: 'Kernel.then/2', desc: 'Pipes value into function (reorder args)', icon: _terminal, docsUrl: _doc('Kernel', 'then', 2), templateExpr: _e2('Kernel.then')),
    NodeEntry(kind: 'function', label: 'Kernel.inspect/1', desc: 'Inspects value as string for debugging', icon: _terminal, docsUrl: _doc('Kernel', 'inspect', 1), templateExpr: _e1('inspect')),
    NodeEntry(kind: 'function', label: 'Kernel.elem/2', desc: 'Gets nth element of tuple', icon: _terminal, docsUrl: _doc('Kernel', 'elem', 2), templateExpr: _e2('elem')),
    NodeEntry(kind: 'function', label: 'Kernel.map_size/1', desc: 'Returns size of map', icon: _terminal, docsUrl: _doc('Kernel', 'map_size', 1), templateExpr: _e1('map_size')),
    NodeEntry(kind: 'function', label: 'Kernel.tuple_size/1', desc: 'Returns size of tuple', icon: _terminal, docsUrl: _doc('Kernel', 'tuple_size', 1), templateExpr: _e1('tuple_size')),
  ]),
  NodeCategory(label: 'Elixir.Code', entries: [
    NodeEntry(kind: 'function', label: 'Code.eval_string/1', desc: 'Evaluates Elixir code string, returns {result, bindings}', icon: _terminal, docsUrl: _doc('Code', 'eval_string', 1), templateExpr: _e1('Code.eval_string')),
    NodeEntry(kind: 'function', label: 'Code.eval_string/2', desc: 'Evaluates with given bindings', icon: _terminal, docsUrl: _doc('Code', 'eval_string', 2), templateExpr: _e2('Code.eval_string')),
  ]),
];
