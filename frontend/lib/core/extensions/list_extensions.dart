extension ListExtension<T> on List<T> {
  // Safe access
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
  
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  // Grouping
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final result = <K, List<T>>{};
    for (final item in this) {
      final key = keyFunction(item);
      (result[key] ??= []).add(item);
    }
    return result;
  }
  
  // Statistics (for numeric lists)
  double get average {
    if (isEmpty) return 0;
    if (T is! num) throw Exception('List must contain numbers');
    return (fold<num>(0, (a, b) => a + (b as num)) / length).toDouble();
  }
  
  T? get mode {
    if (isEmpty) return null;
    final frequency = <T, int>{};
    forEach((element) => frequency[element] = (frequency[element] ?? 0) + 1);
    return frequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  // Budget-specific extensions
  double get total {
    if (isEmpty) return 0;
    if (T is! num) throw Exception('List must contain numbers');
    return fold<num>(0, (a, b) => a + (b as num)).toDouble();
  }
  
  Map<String, double> categoryTotals(String Function(T) categoryGetter, num Function(T) amountGetter) {
    final totals = <String, double>{};
    forEach((item) {
      final category = categoryGetter(item);
      final amount = amountGetter(item).toDouble();
      totals[category] = (totals[category] ?? 0) + amount;
    });
    return totals;
  }
  
  // Pagination
  List<T> paginate({required int page, required int pageSize}) {
    final startIndex = page * pageSize;
    if (startIndex >= length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, length);
    return sublist(startIndex, endIndex);
  }
  
  // Chunking
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }
  
  // Distinct
  List<T> distinct([bool Function(T, T)? equals]) {
    final result = <T>[];
    for (final item in this) {
      if (equals != null) {
        if (!result.any((element) => equals(element, item))) {
          result.add(item);
        }
      } else {
        if (!result.contains(item)) {
          result.add(item);
        }
      }
    }
    return result;
  }
  
  // Safe operations
  List<R> mapIndexed<R>(R Function(int index, T item) convert) {
    final result = <R>[];
    for (var i = 0; i < length; i++) {
      result.add(convert(i, this[i]));
    }
    return result;
  }
  
  void forEachIndexed(void Function(int index, T item) action) {
    for (var i = 0; i < length; i++) {
      action(i, this[i]);
    }
  }
  
  // Sorting helpers
  List<T> sortedBy<K extends Comparable>(K Function(T) selector) {
    final copy = [...this];
    copy.sort((a, b) => selector(a).compareTo(selector(b)));
    return copy;
  }
  
  List<T> sortedByDescending<K extends Comparable>(K Function(T) selector) {
    final copy = [...this];
    copy.sort((a, b) => selector(b).compareTo(selector(a)));
    return copy;
  }
}
