import 'package:aby_pos/app/services/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verifies the right PIN only', () {
    final stored = PinHasher.hash('1234');
    expect(PinHasher.verify('1234', stored), isTrue);
    expect(PinHasher.verify('1235', stored), isFalse);
    expect(PinHasher.verify('', stored), isFalse);
  });

  test('salts each hash and never stores the PIN', () {
    final a = PinHasher.hash('1234');
    final b = PinHasher.hash('1234');
    expect(a, isNot(b));
    expect(a, isNot(contains('1234')));
    expect(a, startsWith('v1\$20000\$'));
  });

  test('rejects malformed stored values', () {
    expect(PinHasher.verify('1234', ''), isFalse);
    expect(PinHasher.verify('1234', 'v2\$1\$AA==\$AA=='), isFalse);
    expect(PinHasher.verify('1234', 'v1\$x\$AA==\$AA=='), isFalse);
  });

  test('PIN format', () {
    expect(PinHasher.isValidPin('0420'), isTrue);
    expect(PinHasher.isValidPin('123'), isFalse);
    expect(PinHasher.isValidPin('12345'), isFalse);
    expect(PinHasher.isValidPin('12a4'), isFalse);
  });
}
