import 'dart:convert';

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((dynamic key, dynamic val) => MapEntry(key.toString(), val));
  }
  if (value is String && value.isNotEmpty) {
    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is Map) return asMap(decoded);
    } on FormatException {
      return <String, dynamic>{};
    }
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  if (value is String && value.isNotEmpty) {
    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    } on FormatException {
      return <dynamic>[];
    }
  }
  return <dynamic>[];
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  return asList(value)
      .where((dynamic item) => item is Map)
      .map(asMap)
      .where((Map<String, dynamic> item) => item.isNotEmpty)
      .toList();
}

const List<String> _listWrappers = <String>[
  'content',
  'data',
  'items',
  'results',
  'products',
  'orders',
  'banners',
  'categories',
  'cart',
  'item',
];

List<Map<String, dynamic>> extractMapList(
  dynamic root, {
  List<String> wrappers = _listWrappers,
  int depth = 0,
}) {
  final List<Map<String, dynamic>> direct = asMapList(root);
  if (direct.isNotEmpty) return direct;
  if (root is! Map) return <Map<String, dynamic>>[];
  if (depth >= 3) return <Map<String, dynamic>>[];
  final Map<String, dynamic> map = asMap(root);
  for (final String key in wrappers) {
    final dynamic candidate = map[key];
    if (candidate == null) continue;
    final List<Map<String, dynamic>> nested = extractMapList(
      candidate,
      wrappers: wrappers,
      depth: depth + 1,
    );
    if (nested.isNotEmpty) return nested;
  }
  return <Map<String, dynamic>>[];
}

Map<String, dynamic> unwrapMap(
  dynamic data, {
  List<String> keys = const <String>['data', 'content', 'result'],
}) {
  Map<String, dynamic> current = asMap(data);
  for (int i = 0; i < 3; i++) {
    dynamic next;
    bool found = false;
    for (final String key in keys) {
      if (current.containsKey(key)) {
        next = current[key];
        found = true;
        break;
      }
    }
    if (!found) break;
    final Map<String, dynamic> map = asMap(next);
    if (map.isEmpty) break;
    current = map;
  }
  return current;
}

dynamic _fieldValue(dynamic value, String? key) {
  if (key == null) return value;
  final map = asMap(value);
  return map[key];
}

String? readString(dynamic value, [String? key]) {
  final raw = _fieldValue(value, key);
  if (raw == null) return null;
  if (raw is String) {
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (raw is num || raw is bool) return raw.toString();
  return null;
}

double? readDouble(dynamic value, [String? key]) {
  final raw = _fieldValue(value, key);
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  return null;
}

int? readInt(dynamic value, [String? key]) {
  final raw = _fieldValue(value, key);
  if (raw == null) return null;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

bool? readBool(dynamic value, [String? key]) {
  final raw = _fieldValue(value, key);
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final String lower = raw.trim().toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  return null;
}

DateTime? readDate(dynamic value, [String? key]) {
  final raw = _fieldValue(value, key);
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is List && raw.isNotEmpty) {
    final List<int> parts = raw.map((dynamic item) => readInt(item) ?? 0).toList();
    final int year = parts.isNotEmpty ? parts[0] : 0;
    final int month = parts.length > 1 ? parts[1] : 1;
    final int day = parts.length > 2 ? parts[2] : 1;
    final int hour = parts.length > 3 ? parts[3] : 0;
    final int minute = parts.length > 4 ? parts[4] : 0;
    final int second = parts.length > 5 ? parts[5] : 0;
    if (year <= 0 || month <= 0 || day <= 0) return null;
    return DateTime(year, month, day, hour, minute, second);
  }
  if (raw is num) {
    final int millis = raw > 1e11 ? raw.toInt() : raw.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  if (raw is String) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  return null;
}
