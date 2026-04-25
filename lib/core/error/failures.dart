import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final List<dynamic> properties;

  const Failure({
    this.message = 'Unexpected error',
    this.properties = const <dynamic>[],
  });

  @override
  List<dynamic> get props => [message, ...properties];
}

// General Failures
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'خطأ في الخادم'});
}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'لا يوجد اتصال بالإنترنت'});
}
