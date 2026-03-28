import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/blocs/plans/helpers.dart';

void main() {
  group('PlansPageInfo', () {
    test('fromJson parses all fields', () {
      final info = PlansPageInfo.fromJson({
        'startCursor': 'cursor_start',
        'endCursor': 'cursor_end',
        'hasNextPage': true,
        'hasPreviousPage': false,
        'searchWindowUsed': 'PT3H',
      });

      expect(info.startCursor, 'cursor_start');
      expect(info.endCursor, 'cursor_end');
      expect(info.hasNextPage, isTrue);
      expect(info.hasPreviousPage, isFalse);
      expect(info.searchWindowUsed, 'PT3H');
    });

    test('fromJson handles null cursors and searchWindow', () {
      final info = PlansPageInfo.fromJson({
        'startCursor': null,
        'endCursor': null,
        'hasNextPage': false,
        'hasPreviousPage': false,
        'searchWindowUsed': null,
      });

      expect(info.startCursor, isNull);
      expect(info.endCursor, isNull);
      expect(info.searchWindowUsed, isNull);
    });

    test('fromJson with hasNextPage=false, hasPreviousPage=true', () {
      final info = PlansPageInfo.fromJson({
        'startCursor': null,
        'endCursor': null,
        'hasNextPage': false,
        'hasPreviousPage': true,
        'searchWindowUsed': null,
      });

      expect(info.hasNextPage, isFalse);
      expect(info.hasPreviousPage, isTrue);
    });
  });
}
