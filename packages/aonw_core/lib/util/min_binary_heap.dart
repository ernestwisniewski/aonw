/// Small deterministic binary min-heap used by hot pathfinding loops.
final class MinBinaryHeap<T> {
  MinBinaryHeap(this._compare);

  final int Function(T first, T second) _compare;
  final List<T> _values = [];

  bool get isEmpty => _values.isEmpty;
  bool get isNotEmpty => _values.isNotEmpty;
  int get length => _values.length;

  void add(T value) {
    _values.add(value);
    var index = _values.length - 1;
    while (index > 0) {
      final parent = (index - 1) >> 1;
      if (_compare(_values[parent], value) <= 0) break;
      _values[index] = _values[parent];
      index = parent;
    }
    _values[index] = value;
  }

  T removeFirst() {
    if (_values.isEmpty) {
      throw StateError('Cannot remove from an empty heap.');
    }
    final first = _values.first;
    final last = _values.removeLast();
    if (_values.isEmpty) return first;

    var index = 0;
    final length = _values.length;
    while (true) {
      final left = index * 2 + 1;
      if (left >= length) break;
      final right = left + 1;
      var child = left;
      if (right < length && _compare(_values[right], _values[left]) < 0) {
        child = right;
      }
      if (_compare(last, _values[child]) <= 0) break;
      _values[index] = _values[child];
      index = child;
    }
    _values[index] = last;
    return first;
  }
}
