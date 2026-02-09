import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_logger.dart';

class AppBlocObserver extends BlocObserver {
  final AppLogger logger;

  AppBlocObserver(this.logger);

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    logger.d('Bloc Event: ${bloc.runtimeType}, Event: $event');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    logger.e(
      'Bloc Error: ${bloc.runtimeType}, Error: $error',
      error,
      stackTrace,
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    logger.d('Bloc Change: ${bloc.runtimeType}, Change: $change');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    logger.d('Bloc Transition: ${bloc.runtimeType}, Transition: $transition');
  }
}
