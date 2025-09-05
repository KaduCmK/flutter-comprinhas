import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ListasRepository _repository;
  final String listId;

  HistoryBloc({required ListasRepository repository, required this.listId})
      : _repository = repository,
        super(const HistoryState()) {
    on<LoadHistory>(_onLoadHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final history = await _repository.getPurchaseHistory(listId);
      emit(state.copyWith(isLoading: false, purchaseHistory: history));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}