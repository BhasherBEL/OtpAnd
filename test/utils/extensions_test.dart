import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/utils/extensions.dart';

void main() {
  group('ListExtensions.firstWhereOrNull', () {
    test('returns first matching element', () {
      final list = [1, 2, 3, 4, 5];
      expect(list.firstWhereOrNull((e) => e > 3), 4);
    });

    test('returns null when no element matches', () {
      final list = [1, 2, 3];
      expect(list.firstWhereOrNull((e) => e > 10), isNull);
    });

    test('returns null for empty list', () {
      final list = <int>[];
      expect(list.firstWhereOrNull((e) => e > 0), isNull);
    });

    test('returns first match, not last', () {
      final list = [10, 20, 30];
      expect(list.firstWhereOrNull((e) => e > 5), 10);
    });

    test('works with strings', () {
      final list = ['apple', 'banana', 'cherry'];
      expect(list.firstWhereOrNull((e) => e.startsWith('b')), 'banana');
    });

    test('returns null when test never matches strings', () {
      final list = ['apple', 'banana'];
      expect(list.firstWhereOrNull((e) => e.startsWith('z')), isNull);
    });
  });

  group('DateTimeExtensions.daysDifference', () {
    test('same day → 0', () {
      final a = DateTime(2024, 1, 15, 10, 30);
      final b = DateTime(2024, 1, 15, 22, 0);
      expect(a.daysDifference(b), 0);
    });

    test('one day ahead → 1', () {
      final a = DateTime(2024, 1, 15);
      final b = DateTime(2024, 1, 16);
      expect(a.daysDifference(b), 1);
    });

    test('one week ahead → 7', () {
      final a = DateTime(2024, 1, 1);
      final b = DateTime(2024, 1, 8);
      expect(a.daysDifference(b), 7);
    });

    test('negative difference (b before a)', () {
      final a = DateTime(2024, 1, 10);
      final b = DateTime(2024, 1, 5);
      expect(a.daysDifference(b), -5);
    });

    test('ignores time-of-day when computing difference', () {
      final a = DateTime(2024, 1, 15, 23, 59);
      final b = DateTime(2024, 1, 16, 0, 1);
      expect(a.daysDifference(b), 1);
    });

    test('cross-month boundary', () {
      final a = DateTime(2024, 1, 31);
      final b = DateTime(2024, 2, 2);
      expect(a.daysDifference(b), 2);
    });
  });
}
