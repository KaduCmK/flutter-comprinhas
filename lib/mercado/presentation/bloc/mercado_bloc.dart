import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:logger/logger.dart';

part 'mercado_event.dart';
part 'mercado_state.dart';

class MercadoBloc extends Bloc<MercadoEvent, MercadoState> {
  final _logger = Logger();
  final MercadoRepository _repository;

  MercadoBloc({required MercadoRepository mercadoRepository})
    : _repository = mercadoRepository,
      super(MercadoInitial()) {
    on<SendNfe>((event, emit) async {
      _logger.d('Enviando NF-E | ${event.nfe}');
      emit(SendingNfe());
      try {
        // await _repository.sendNfe(event.nfe);
        _logger.i('NF-E enviada com sucesso');
        emit(NfeSent());
      } catch (e) {
        _logger.e(e);
        emit(MercadoError(e.toString()));
      }
    });
  }
}
