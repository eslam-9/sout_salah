import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/features/mosques/domain/factories/ramadan_month_factory.dart';

void main() {
  group('RamadanMonthFactory', () {
    test('createDays should generate exactly 30 days', () {
      final days = RamadanMonthFactory.createDays(
        mosqueId: 'mosque-123',
        month: 9,
        year: 1445,
      );
      expect(days.length, 30);
    });

    test('createDays should populate correctly mapped properties', () {
      final days = RamadanMonthFactory.createDays(
        mosqueId: 'mosque-123',
        month: 9,
        year: 1445,
      );

      final firstDay = days.first;
      expect(firstDay['mosque_id'], 'mosque-123');
      expect(firstDay['day_number'], 1);
      expect(firstDay['month'], 9);
      expect(firstDay['year'], 1445);
      expect(firstDay['status'], 'red');
      expect(firstDay['active'], true);

      final lastDay = days.last;
      expect(lastDay['day_number'], 30);
    });
  });
}
