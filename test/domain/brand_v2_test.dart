import 'dart:io';
import 'dart:typed_data';

import 'package:aby_pos/app/domain/category_icons.dart';
import 'package:aby_pos/app/models/enums.dart';
import 'package:aby_pos/app/modules/till/views/till_view.dart' show gridShape;
import 'package:aby_pos/app/services/hub/hub_service.dart';
import 'package:aby_pos/app/services/product_photo.dart';
import 'package:aby_pos/app/theme/aby_colors.dart';
import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:aby_pos/app/theme/category_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('category pictures', () {
    test('a picture is guessed from the name', () {
      String guess(String name) => guessCategoryIcon(name, CategoryTone.blue);
      expect(guess('Cones'), 'ice-cream-cone');
      expect(guess('Ice cream cups'), 'ice-cream-bowl');
      expect(guess('Tubs'), 'ice-cream-bowl');
      expect(guess('Hot drinks'), 'coffee');
      expect(guess('Drinks'), 'cup-soda');
      expect(guess('Milkshakes'), 'cup-soda');
      expect(guess('Alcoholic drinks'), 'beer');
      expect(guess('Meat pies'), 'croissant');
      expect(guess('Cakes'), 'cake-slice');
      expect(guess('Jollof and rice'), 'utensils');
      expect(guess('Toppings'), 'candy');
    });

    test('words match where they start, so "tea" is not "steak"', () {
      expect(guessCategoryIcon('Teas', CategoryTone.blue), 'coffee');
      expect(guessCategoryIcon('Steak', CategoryTone.blue), isNot('coffee'));
      expect(guessCategoryIcon('Cupcakes', CategoryTone.blue), 'cake-slice');
    });

    test('shops that are not food get their own pictures', () {
      String guess(String name) => guessCategoryIcon(name, CategoryTone.blue);
      expect(guess('Medicines'), 'pill');
      expect(guess('First aid'), 'heart-pulse');
      expect(guess('Baby'), 'baby');
      expect(guess('Personal care'), 'sparkles');
      expect(guess('Services'), 'scissors');
      expect(guess('Women'), 'shirt');
      expect(guess('Men'), 'shirt');
      expect(guess('Phones'), 'smartphone');
      expect(guess('Airtime and data'), 'smartphone');
      expect(guess('Electrical'), 'zap');
      expect(guess('Plumbing'), 'wrench');
      expect(guess('Cement and blocks'), 'hammer');
      expect(guess('Household'), 'house');
    });

    test('a name it does not know gets the shopping bag', () {
      expect(guessCategoryIcon('Odds and ends', CategoryTone.midnight), 'shopping-bag');
    });

    test('every picture has its icon file, and every colour its paint', () {
      for (final icon in categoryIcons) {
        expect(File('assets/icons/ui/$icon.svg').existsSync(), isTrue, reason: icon);
      }
      expect(categoryIcons.toSet(), hasLength(categoryIcons.length), reason: 'no picture twice');
      for (final c in [AbyColors.light, AbyColors.dark]) {
        final paints = {for (final t in CategoryTone.values) tonePaint(t, c).dot};
        expect(paints, hasLength(CategoryTone.values.length), reason: 'each colour is its own');
      }
    });

    test('the owner\'s pick wins, unless it is not in the set', () {
      expect(categoryIconFor(name: 'Drinks', tone: CategoryTone.blue, picked: 'pizza'), 'pizza');
      expect(categoryIconFor(name: 'Drinks', tone: CategoryTone.blue, picked: 'rocket'), 'cup-soda');
    });
  });

  group('pairing codes', () {
    test('typed codes match the hub\'s whatever the case or dash', () {
      expect(PairingOffer.normalizeCode('abcd-efgh'), 'ABCDEFGH');
      expect(PairingOffer.normalizeCode(' AB CD EF GH '), 'ABCDEFGH');
      expect(PairingOffer.formatCode('ABCDEFGH'), 'ABCD-EFGH');
      expect(PairingOffer.formatCode('abc'), 'ABC');
    });

    test('the QR text still reads back', () {
      final offer = PairingOffer(code: 'ABCDEFGH', hubId: 'hub-1', urls: const ['http://10.0.0.2:8787'], expires: DateTime(2030));
      final (urls, code, hubId) = PairingOffer.parse(offer.qr)!;
      expect(urls, ['http://10.0.0.2:8787']);
      expect((code, hubId), ('ABCDEFGH', 'hub-1'));
      expect(PairingOffer.parse('ABCD-EFGH'), isNull);
    });
  });

  group('product photos', () {
    test('a wide photo comes out square, small, and under 60 KB', () {
      final wide = img.Image(width: 1600, height: 900);
      // Noise is the hardest case for compression.
      for (final p in wide) {
        p
          ..r = (p.x * 7 + p.y * 13) % 256
          ..g = (p.x * p.y) % 256
          ..b = (p.x ^ p.y) % 256;
      }
      final out = squareProductPhotoSync(img.encodePng(wide))!;
      final decoded = img.decodeImage(out)!;
      expect(decoded.width, decoded.height);
      expect(decoded.width, lessThanOrEqualTo(480));
      expect(out.length, lessThanOrEqualTo(productPhotoMaxBytes));
    });

    test('a small photo is not blown up, and not-a-picture is null', () {
      final out = squareProductPhotoSync(img.encodePng(img.Image(width: 300, height: 400)))!;
      expect(img.decodeImage(out)!.width, 300);
      expect(squareProductPhotoSync(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });

  group('till grid', () {
    test('tiles are never narrower than the brand minimum', () {
      for (final width in [280.0, 320.0, 400.0, 600.0, 900.0, 1400.0]) {
        for (final target in [160.0, 200.0, 250.0]) {
          final (columns, _) = gridShape(width: width, target: target, textHeight: 100);
          final tile = (width - AbySpace.s3 * (columns - 1)) / columns;
          if (columns > 1) expect(tile, greaterThanOrEqualTo(AbySize.tileMin), reason: '$width / $target');
        }
      }
    });

    test('the photo keeps 4:3 at any width', () {
      final (columns, extent) = gridShape(width: 600, target: 200, textHeight: 100);
      final tile = (600 - AbySpace.s3 * (columns - 1)) / columns;
      final photo = extent - 100 - 3;
      expect(photo / (tile - AbySpace.s2 * 2 - 3), closeTo(0.75, 0.001));
    });
  });
}
