import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/features/mosques/domain/entities/prayer.dart';

void main() {
  group('Prayer Entity', () {
    test('resolvedName should return englishName for standard prayers', () {
      expect(Prayer.fajr.resolvedName(null), 'Fajr');
      expect(Prayer.fajr.resolvedName('Custom'), 'Fajr'); // Custom name is ignored
      expect(Prayer.taraweeh1.resolvedName(null), 'Taraweeh 1');
    });

    test('resolvedArabicName should return arabicName for standard prayers', () {
      expect(Prayer.maghrib.resolvedArabicName(null), 'المغرب');
      expect(Prayer.maghrib.resolvedArabicName('Custom'), 'المغرب'); // Custom name is ignored
    });

    test('resolvedName should return customName for "other" prayer if provided', () {
      expect(Prayer.other.resolvedName('Qiyam'), 'Qiyam');
      expect(Prayer.other.resolvedName(null), 'Other');
      expect(Prayer.other.resolvedName(''), 'Other');
    });

    test('resolvedArabicName should return customName for "other" prayer if provided', () {
      expect(Prayer.other.resolvedArabicName('قيام الليل'), 'قيام الليل');
      expect(Prayer.other.resolvedArabicName(null), 'أخرى');
      expect(Prayer.other.resolvedArabicName(''), 'أخرى');
    });

    test('fromString should parse valid names correctly', () {
      expect(Prayer.fromString('Fajr'), Prayer.fajr);
      expect(Prayer.fromString('Taraweeh 2'), Prayer.taraweeh2);
      expect(Prayer.fromString('Witr'), Prayer.witr);
    });

    test('fromString should fallback to "other" for unknown names', () {
      expect(Prayer.fromString('Unknown Prayer'), Prayer.other);
      expect(Prayer.fromString(''), Prayer.other);
    });
  });
}
