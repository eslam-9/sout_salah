import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/features/mosques/domain/services/ramadan_status_service.dart';

void main() {
  group('RamadanStatusService', () {
    test('should return "red" when recordingsCount is 0', () {
      final result = RamadanStatusService.computeStatus(0);
      expect(result, 'red');
    });

    test('should return "yellow" when recordingsCount is between 1 and 4', () {
      expect(RamadanStatusService.computeStatus(1), 'yellow');
      expect(RamadanStatusService.computeStatus(2), 'yellow');
      expect(RamadanStatusService.computeStatus(3), 'yellow');
      expect(RamadanStatusService.computeStatus(4), 'yellow');
    });

    test('should return "green" when recordingsCount is 5 or more', () {
      expect(RamadanStatusService.computeStatus(5), 'green');
      expect(RamadanStatusService.computeStatus(10), 'green');
    });
  });
}
