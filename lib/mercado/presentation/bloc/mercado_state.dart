part of 'mercado_bloc.dart';

sealed class MercadoState extends Equatable {
  const MercadoState();
  
  @override
  List<Object> get props => [];
}

final class MercadoInitial extends MercadoState {}

final class MercadoLoading extends MercadoState {}

final class MercadoSuccess extends MercadoState {}

final class MercadoError extends MercadoState {
  final String message;

  const MercadoError(this.message);

  @override
  List<Object> get props => [message];
}

final class SendingNfe extends MercadoState {}

final class NfeSent extends MercadoState {}