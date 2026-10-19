import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';

void main() {
  group('groupLakh', () {
    test('small numbers are unchanged', () {
      expect(groupLakh(0), '0');
      expect(groupLakh(7), '7');
      expect(groupLakh(999), '999');
    });

    test('thousands, lakhs and crores', () {
      expect(groupLakh(1000), '1,000');
      expect(groupLakh(18420), '18,420');
      expect(groupLakh(125000), '1,25,000');
      expect(groupLakh(1000000), '10,00,000');
      expect(groupLakh(12500000), '1,25,00,000');
    });
  });

  group('formatTaka', () {
    test('whole taka hides poisha', () {
      expect(formatTaka(64500), '৳645');
      expect(formatTaka(12500000), '৳1,25,000');
    });

    test('shows poisha when present', () {
      expect(formatTaka(25050), '৳250.50');
      expect(formatTaka(5), '৳0.05');
    });

    test('negative and options', () {
      expect(formatTaka(-18000), '-৳180');
      expect(formatTaka(100, alwaysShowPoisha: true), '৳1.00');
      expect(formatTaka(100000, withSign: false), '1,000');
    });
  });

  group('parseTakaToPoisha', () {
    test('valid input', () {
      expect(parseTakaToPoisha('250'), 25000);
      expect(parseTakaToPoisha('250.5'), 25050);
      expect(parseTakaToPoisha('1,250.75'), 125075);
      expect(parseTakaToPoisha('৳ 10'), 1000);
      expect(parseTakaToPoisha('0.'), 0);
    });

    test('invalid input', () {
      expect(parseTakaToPoisha(''), isNull);
      expect(parseTakaToPoisha('abc'), isNull);
      expect(parseTakaToPoisha('1.234'), isNull);
      expect(parseTakaToPoisha('-5'), isNull);
    });
  });
}
