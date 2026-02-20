import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final List<dynamic> properties;

  const Failure([this.properties = const <dynamic>[]]);

  @override
  List<dynamic> get props => properties;
}

// General Failures
class ServerFailure extends Failure {
  final String? message;
  const ServerFailure([this.message]);
}

class CacheFailure extends Failure {}
