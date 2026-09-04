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

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'خطأ في المصادقة'});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'العنصر غير موجود'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'بيانات غير صالحة'});
}

class StorageFailure extends Failure {
  const StorageFailure({super.message = 'خطأ في التخزين السحابي'});
}
