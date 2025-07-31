import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';

part 'global_cart_event.dart';
part 'global_cart_state.dart';

class GlobalCartBloc extends Bloc<GlobalCartEvent, GlobalCartState> {
  final ListasRepository _repository;

  GlobalCartBloc({required ListasRepository repository})
    : _repository = repository,
      super(GlobalCartState()) {
    on<LoadGlobalCartEvent>(_onLoadGlobalCart);
  }

  Future<void> _onLoadGlobalCart(
    LoadGlobalCartEvent event,
    Emitter<GlobalCartState> emit,
  ) async {
    emit(const GlobalCartState(isLoading: true));
    try {
      final items = await _repository.getCartItems(null);
      emit(GlobalCartState(cartItems: items));
    } catch (e) {
      emit(GlobalCartState(error: e.toString()));
    }
  }
}
