import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';

import 'close_purchase_with_nfe_state.dart';

typedef CartItemIdsResolver = List<String> Function();
typedef PurchaseConfirmedCallback = void Function();

class ClosePurchaseWithNfeCubit extends Cubit<ClosePurchaseWithNfeState> {
  final ListasRepository _repository;
  final CartItemIdsResolver _cartItemIdsResolver;
  final PurchaseConfirmedCallback? _onPurchaseConfirmed;

  ClosePurchaseWithNfeCubit({
    required ListasRepository repository,
    required CartItemIdsResolver cartItemIdsResolver,
    PurchaseConfirmedCallback? onPurchaseConfirmed,
  }) : _repository = repository,
       _cartItemIdsResolver = cartItemIdsResolver,
       _onPurchaseConfirmed = onPurchaseConfirmed,
       super(const ClosePurchaseWithNfeState());

  Future<void> loadPreview(String accessKey) async {
    final normalizedAccessKey = accessKey.trim();
    if (normalizedAccessKey.length != 44) {
      emit(
        state.copyWith(
          status: ClosePurchaseWithNfeStatus.failure,
          errorMessage: 'Informe uma chave de acesso válida com 44 dígitos.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ClosePurchaseWithNfeStatus.loadingPreview,
        manualMatches: const {},
        clearPreview: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final preview = await _repository.previewPurchaseWithNfe(
        _cartItemIdsResolver(),
        normalizedAccessKey,
      );
      emit(
        state.copyWith(
          status: ClosePurchaseWithNfeStatus.previewReady,
          preview: preview,
          manualMatches: const {},
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ClosePurchaseWithNfeStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void setManualMatch(String cartItemId, String? value) {
    final updatedMatches = Map<String, String>.from(state.manualMatches);
    if (value == null) {
      updatedMatches.remove(cartItemId);
    } else {
      updatedMatches[cartItemId] = value;
    }

    emit(
      state.copyWith(
        status:
            state.preview != null
                ? ClosePurchaseWithNfeStatus.previewReady
                : state.status,
        manualMatches: updatedMatches,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> confirmPurchase(String accessKey) async {
    if (!state.canConfirm) return;

    emit(
      state.copyWith(
        status: ClosePurchaseWithNfeStatus.confirming,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository
          .confirmPurchaseWithNfe(_cartItemIdsResolver(), accessKey.trim(), {
            for (final entry in state.manualMatches.entries)
              entry.key:
                  entry.value == ClosePurchaseWithNfeUi.ignoreCartItemSelection
                      ? null
                      : entry.value,
          });
      _onPurchaseConfirmed?.call();
      emit(
        state.copyWith(
          status: ClosePurchaseWithNfeStatus.success,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ClosePurchaseWithNfeStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void acknowledgeSuccess() {
    if (state.status != ClosePurchaseWithNfeStatus.success) return;

    emit(
      state.copyWith(
        status:
            state.preview != null
                ? ClosePurchaseWithNfeStatus.previewReady
                : ClosePurchaseWithNfeStatus.initial,
      ),
    );
  }
}
