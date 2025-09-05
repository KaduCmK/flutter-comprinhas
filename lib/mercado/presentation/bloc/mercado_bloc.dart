import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/config/notification_service.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:logger/logger.dart';

part 'mercado_event.dart';
part 'mercado_state.dart';

class MercadoBloc extends Bloc<MercadoEvent, MercadoState> {
  final _logger = Logger();
  final MercadoRepository _repository;
  final NotificationService _notificationService;

  MercadoBloc({
    required MercadoRepository mercadoRepository,
    required NotificationService notificationService,
  })  : _repository = mercadoRepository,
        _notificationService = notificationService,
        super(MercadoInitial()) {
    on<SendNfe>((event, emit) async {
      final accessKey = event.nfe; // Agora recebe a chave limpa
      _logger.d('Enviando NF-e | $accessKey');

      // A validação do formato da chave já foi feita na tela do scanner.
      // Apenas uma verificação final por segurança.
      if (accessKey.length != 44 || BigInt.tryParse(accessKey) == null) {
        emit(MercadoError("Chave de acesso com formato inválido recebida."));
        return;
      }

      emit(SendingNfe());
      await _notificationService.showPersistentNotification(
        id: 0,
        title: 'Enviando Nota Fiscal',
        body: 'Aguarde enquanto processamos a sua nota fiscal.',
      );
      try {
        await _repository.sendNfe(accessKey); // Envia a chave limpa
        _logger.i('NF-E enviada com sucesso');
        await _notificationService.cancelNotification(0);
        emit(NfeSent());
      } catch (e) {
        _logger.e(e);
        await _notificationService.cancelNotification(0);
        await _notificationService.showNotification(
          id: 1,
          title: 'Erro ao Enviar Nota Fiscal',
          body: e.toString(),
        );
        emit(MercadoError(e.toString()));
      }
    });
  }
}