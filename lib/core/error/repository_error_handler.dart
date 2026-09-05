import 'package:dartz/dartz.dart';
import 'exceptions.dart';
import 'failures.dart';

Future<Either<Failure, T>> executeWithCatch<T>(Future<T> Function() action) async {
  try {
    final result = await action();
    return Right(result);
  } on NetworkException catch (e) {
    return Left(NetworkFailure(message: e.message ?? 'لا يوجد اتصال بالإنترنت'));
  } on AppAuthException catch (e) {
    return Left(AuthFailure(message: e.message ?? 'خطأ في المصادقة'));
  } on NotFoundException catch (e) {
    return Left(NotFoundFailure(message: e.message ?? 'العنصر غير موجود'));
  } on ValidationException catch (e) {
    return Left(ValidationFailure(message: e.message ?? 'بيانات غير صالحة'));
  } on StorageException catch (e) {
    return Left(StorageFailure(message: e.message ?? 'خطأ في التخزين السحابي'));
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message ?? 'خطأ في الخادم'));
  } on LocationPermissionDeniedException {
    return const Left(LocationPermissionDeniedFailure());
  } on LocationPermissionPermanentlyDeniedException {
    return const Left(LocationPermissionPermanentlyDeniedFailure());
  } on LocationServiceDisabledException {
    return const Left(LocationServiceDisabledFailure());
  } on LocationUnavailableException {
    return const Left(LocationUnavailableFailure());
  } on MapLaunchException {
    return const Left(MapLaunchFailure());
  } catch (e) {
    final message = e.toString().replaceAll('Exception: ', '');
    return Left(ServerFailure(message: message));
  }
}
