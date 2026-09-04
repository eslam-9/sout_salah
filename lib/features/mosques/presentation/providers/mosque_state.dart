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
  final List<Mosque> mosques;
  const MosqueLoaded(this.mosques);
  @override
  List<Object> get props => [mosques];
}

class RamadanDaysLoaded extends MosqueState {
  final List<RamadanDay> days;
  const RamadanDaysLoaded(this.days);
  @override
  List<Object> get props => [days];
}

class RecordingsLoaded extends MosqueState {
  final List<Recording> recordings;
  const RecordingsLoaded(this.recordings);
  @override
  List<Object> get props => [recordings];
}

class MosqueError extends MosqueState {
  final String message;
  const MosqueError(this.message);
  @override
  List<Object> get props => [message];
}
