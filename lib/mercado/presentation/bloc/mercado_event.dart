part of 'mercado_bloc.dart';

sealed class MercadoEvent extends Equatable {
  const MercadoEvent();

  @override
  List<Object?> get props => [];
}

final class SendNfe extends MercadoEvent {
  final String nfe;

  const SendNfe(this.nfe);

  @override
  List<Object?> get props => [nfe];
}
