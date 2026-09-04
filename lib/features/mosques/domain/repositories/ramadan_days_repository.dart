import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ramadan_day.dart';

abstract class RamadanDaysRepository {
  Future<Either<Failure, List<RamadanDay>>> getRamadanDays(
    String mosqueId, {
    int? month,
    int? year,
  });
  Future<Either<Failure, void>> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  });
  Future<Either<Failure, List<Map<String, int>>>> getAvailableMonths(
    String mosqueId,
  );
}
