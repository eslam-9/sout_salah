import 'dart:async';
import 'package:dartz/dartz.dart';
import '../error/failures.dart';
import 'network_info.dart';
import 'network_policy.dart';

/// A mixin that gives StateNotifiers a single,
/// well-tested retry/timeout executor.
mixin RetryExecutorMixin {
  /// Executes a future with timeout, connectivity check, and retry mechanism
  Future<Either<Failure, T>> executeWithRetry<T>(
    Future<Either<Failure, T>> Function() operation, {
    NetworkInfo? networkInfo,
  }) async {
    // 1. Fast fail if offline
    if (networkInfo != null) {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure());
      }
    }

    int attempt = 0;
    while (attempt <= NetworkPolicy.maxRetryAttempts) {
      try {
        // Create a timeout for the operation
        final result = await operation().timeout(
          NetworkPolicy.requestTimeout,
          onTimeout: () =>
              const Left(ServerFailure(message: 'انتهى وقت الطلب')),
        );

        // If successful, return the result
        if (result.isRight()) {
          return result;
        }

        // If we got a failure, check if it's a ServerFailure before retrying
        final failure = result.fold((l) => l, (r) => null);
        if (failure is NetworkFailure) {
          return result; // Don't retry on clear network failures
        }

        attempt++;
        if (attempt > NetworkPolicy.maxRetryAttempts) {
          return result; // Return the failure after max attempts
        }

        // Wait before retrying (exponential backoff capped at reasonable time)
        await Future.delayed(Duration(seconds: attempt * 2));
      } on TimeoutException catch (_) {
        attempt++;
        if (attempt > NetworkPolicy.maxRetryAttempts) {
          return const Left(ServerFailure(message: 'انتهى وقت الطلب'));
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        attempt++;
        if (attempt > NetworkPolicy.maxRetryAttempts) {
          return Left(ServerFailure(message: e.toString()));
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return const Left(
      ServerFailure(message: 'تجاوز الحد الأقصى لمحاولات إعادة الاتصال'),
    );
  }

  String mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return 'خطأ في التخزين المؤقت';
    } else {
      return failure.message;
    }
  }
}
