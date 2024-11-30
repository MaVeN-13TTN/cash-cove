import 'dart:async';
import 'package:hive/hive.dart';

class CacheAnalytics {
  static const String _boxName = 'cache_analytics';
  final Box<Map> _box;
  final _analyticsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get analyticsStream => _analyticsController.stream;

  CacheAnalytics(this._box);

  static Future<CacheAnalytics> initialize() async {
    final box = await Hive.openBox<Map>(_boxName);
    return CacheAnalytics(box);
  }

  Future<void> recordHit(String key, int size) async {
    final stats = _getStats(key);
    stats['hits'] = (stats['hits'] as int) + 1;
    stats['lastHit'] = DateTime.now().toIso8601String();
    stats['size'] = size;
    await _saveStats(key, stats);
    _notifyListeners();
  }

  Future<void> recordMiss(String key) async {
    final stats = _getStats(key);
    stats['misses'] = (stats['misses'] as int) + 1;
    stats['lastMiss'] = DateTime.now().toIso8601String();
    await _saveStats(key, stats);
    _notifyListeners();
  }

  Future<void> recordEviction(String key) async {
    final stats = _getStats(key);
    stats['evictions'] = (stats['evictions'] as int) + 1;
    stats['lastEviction'] = DateTime.now().toIso8601String();
    await _saveStats(key, stats);
    _notifyListeners();
  }

  Map<String, dynamic> _getStats(String key) {
    return Map<String, dynamic>.from(_box.get(key) ?? {
      'hits': 0,
      'misses': 0,
      'evictions': 0,
      'size': 0,
      'firstSeen': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _saveStats(String key, Map<String, dynamic> stats) async {
    await _box.put(key, stats);
  }

  void _notifyListeners() {
    final analytics = <String, dynamic>{
      'totalHits': 0,
      'totalMisses': 0,
      'totalEvictions': 0,
      'totalSize': 0,
      'hitRatio': 0.0,
      'entries': <String, Map<String, dynamic>>{},
    };

    for (final key in _box.keys) {
      final stats = _getStats(key as String);
      analytics['entries'][key] = stats;
      analytics['totalHits'] += stats['hits'] as int;
      analytics['totalMisses'] += stats['misses'] as int;
      analytics['totalEvictions'] += stats['evictions'] as int;
      analytics['totalSize'] += stats['size'] as int;
    }

    final totalRequests = analytics['totalHits'] + analytics['totalMisses'];
    analytics['hitRatio'] = totalRequests > 0
        ? analytics['totalHits'] / totalRequests
        : 0.0;

    _analyticsController.add(analytics);
  }

  Future<void> clearStats() async {
    await _box.clear();
    _notifyListeners();
  }

  Future<void> dispose() async {
    await _analyticsController.close();
    await _box.close();
  }
}
