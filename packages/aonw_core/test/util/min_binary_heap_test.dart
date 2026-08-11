import 'package:aonw_core/util/min_binary_heap.dart';
import 'package:test/test.dart';

void main() {
  test('reports empty state and rejects removing a missing value', () {
    final heap = MinBinaryHeap<int>((first, second) => first.compareTo(second));

    expect(heap.isEmpty, isTrue);
    expect(heap.length, 0);
    expect(heap.removeFirst, throwsStateError);
  });

  test('returns values in comparator order', () {
    final heap = MinBinaryHeap<int>((first, second) => first.compareTo(second));
    for (final value in [7, 2, 9, 2, 4, 1]) {
      heap.add(value);
    }

    final ordered = <int>[];
    while (heap.isNotEmpty) {
      ordered.add(heap.removeFirst());
    }

    expect(ordered, [1, 2, 2, 4, 7, 9]);
  });
}
