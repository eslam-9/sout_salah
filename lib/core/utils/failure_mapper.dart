import '../error/failures.dart';

/// Maps a [Failure] to a user-facing Arabic error message.
/// Use this single source of truth instead of duplicating _mapFailureToMessage.
String mapFailureToMessage(Failure failure) {
  if (failure is NetworkFailure) return failure.message;
  if (failure is ServerFailure) return failure.message;
  if (failure is AuthFailure) return failure.message;
  if (failure is NotFoundFailure) return failure.message;
  if (failure is ValidationFailure) return failure.message;
  if (failure is StorageFailure) return failure.message;
  if (failure is CacheFailure) return 'خطأ في التخزين المؤقت';
  return failure.message;
}
