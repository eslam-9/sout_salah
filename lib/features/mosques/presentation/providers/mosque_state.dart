import 'package:equatable/equatable.dart';

import '../../domain/entities/mosque.dart';
import '../../domain/entities/ramadan_day.dart';
import '../../domain/entities/recording.dart';

abstract class MosqueState extends Equatable {
  const MosqueState();
  @override
  List<Object> get props => [];
}

class MosqueInitial extends MosqueState {}

class MosqueLoading extends MosqueState {}

class MosqueLoaded extends MosqueState {
  const MosqueLoaded(this.mosques);
  final List<Mosque> mosques;
  @override
  List<Object> get props => [mosques];
}

class RamadanDaysLoaded extends MosqueState {
  const RamadanDaysLoaded(this.days);
  final List<RamadanDay> days;
  @override
  List<Object> get props => [days];
}

class RecordingsLoaded extends MosqueState {
  const RecordingsLoaded(this.recordings);
  final List<Recording> recordings;
  @override
  List<Object> get props => [recordings];
}

class MosqueError extends MosqueState {
  const MosqueError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
