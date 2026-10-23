import 'package:aby_pos/app/services/money.dart';
import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoney', () {
    test('formats pesewas as GH₵ with two decimals', () {
      expect(formatMoney(0), 'GH₵ 0.00');
      expect(formatMoney(5), 'GH₵ 0.05');
      expect(formatMoney(1500), 'GH₵ 15.00');
      expect(formatMoney(123400), 'GH₵ 1,234.00');
      expect(formatMoney(123456789), 'GH₵ 1,234,567.89');
    });

    test('puts the sign before the currency', () {
      expect(formatMoney(-2550), '-GH₵ 25.50');
    });

    test('matches the brand kit abyMoney()', () {
      for (final p in [0, 1, 99, 100, 1500, 99999, 123400, 100000000]) {
        expect(formatMoney(p), abyMoney(p / 100), reason: '$p pesewas');
      }
    });
  });

  group('parseMoney', () {
    test('reads cedis and pesewas', () {
      expect(parseMoney('50'), 5000);
      expect(parseMoney('50.5'), 5050);
      expect(parseMoney('50.05'), 5005);
      expect(parseMoney('.5'), 50);
      expect(parseMoney('5.'), 500);
      expect(parseMoney('1,000.25'), 100025);
      expect(parseMoney(' GH₵ 20 '), 2000);
    });

    test('rejects what is not an amount', () {
      expect(parseMoney(''), isNull);
      expect(parseMoney('.'), isNull);
      expect(parseMoney('abc'), isNull);
      expect(parseMoney('1.234'), isNull);
      expect(parseMoney('-5'), isNull);
      expect(parseMoney('1.2.3'), isNull);
    });

    test('avoids floating point drift', () {
      // 0.1 + 0.2 != 0.3 in doubles; pesewas add exactly.
      expect(parseMoney('0.10')! + parseMoney('0.20')!, parseMoney('0.30'));
      expect(parseMoney('19.99')! * 3, 5997);
    });
  });

  test('cedis() converts whole cedis', () {
    expect(cedis(15), 1500);
    expect(cedis(0), 0);
  });
}
