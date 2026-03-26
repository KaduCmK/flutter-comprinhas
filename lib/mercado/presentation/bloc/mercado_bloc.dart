import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/config/notification_service.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
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
  }) : _repository = mercadoRepository,
       _notificationService = notificationService,
       super(const MercadoState()) {
    on<LoadNfeHistory>((event, emit) async {
      emit(state.copyWith(status: MercadoStatus.loading));
      try {
        final history = await _repository.getNfeHistory();
        final topMercados = await _repository.getTopMercados();
        emit(state.copyWith(
          status: MercadoStatus.success, 
          history: history,
          topMercados: topMercados,
        ));
      } catch (e) {
        _logger.e(e);
        emit(
          state.copyWith(
            status: MercadoStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
    });

    on<ClearError>((event, emit) {
      emit(state.copyWith(status: MercadoStatus.initial, errorMessage: null));
    });

    on<SendNfe>((event, emit) async {
      final accessKey = event.nfe;
      _logger.d('Enviando NF-e | $accessKey');

      if (accessKey.length != 44 || BigInt.tryParse(accessKey) == null) {
        emit(
          state.copyWith(
            status: MercadoStatus.error,
            errorMessage: "Chave de acesso com formato inválido recebida.",
          ),
        );
        return;
      }

      emit(state.copyWith(status: MercadoStatus.sending));
      await _notificationService.showPersistentNotification(
        id: 0,
        title: 'Enviando Nota Fiscal',
        body: 'Aguarde enquanto processamos a sua nota fiscal.',
      );
      try {
        await _repository.sendNfe(accessKey);
        _logger.i('NF-E enviada com sucesso');
        await _notificationService.cancelNotification(0);
        emit(state.copyWith(status: MercadoStatus.sent));
        add(LoadNfeHistory());
      } catch (e) {
        _logger.e(e);
        await _notificationService.cancelNotification(0);
        await _notificationService.showNotification(
          id: 1,
          title: 'Erro ao Enviar Nota Fiscal',
          body: e.toString(),
        );
        emit(
          state.copyWith(
            status: MercadoStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
    });
  }
}
