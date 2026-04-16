import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/purchase_with_nfe_preview.dart';

enum ClosePurchaseWithNfeStatus {
  initial,
  loadingPreview,
  previewReady,
  confirming,
  success,
  failure,
}

class ClosePurchaseWithNfeState extends Equatable {
  final ClosePurchaseWithNfeStatus status;
  final PurchaseWithNfePreview? preview;
  final Map<String, String> manualMatches;
  final String? errorMessage;

  const ClosePurchaseWithNfeState({
    this.status = ClosePurchaseWithNfeStatus.initial,
    this.preview,
    this.manualMatches = const {},
    this.errorMessage,
  });

  bool get isLoadingPreview =>
      status == ClosePurchaseWithNfeStatus.loadingPreview;
  bool get isConfirming => status == ClosePurchaseWithNfeStatus.confirming;

  bool get canConfirm {
    if (preview == null || isConfirming) return false;

    for (final item in preview!.cartItems.where((item) => item.needsReview)) {
      if (!manualMatches.containsKey(item.cartItemId)) {
        return false;
      }
    }

    return true;
  }

  Set<String> get selectedInvoiceItemTempIds {
    final preview = this.preview;
    if (preview == null) return const {};

    final selectedIds = <String>{};
    for (final item in preview.cartItems) {
      if (item.status == CartReviewStatus.matched &&
          item.selectedInvoiceItemTempId != null) {
        selectedIds.add(item.selectedInvoiceItemTempId!);
      }

      if (item.status == CartReviewStatus.ambiguous) {
        final manualSelection = manualMatches[item.cartItemId];
        if (manualSelection != null &&
            manualSelection != ClosePurchaseWithNfeUi.ignoreCartItemSelection) {
          selectedIds.add(manualSelection);
        }
      }
    }

    return selectedIds;
  }

  List<InvoiceExtraItem> get displayedExtraItems {
    final preview = this.preview;
    if (preview == null) return const [];

    final selectedIds = selectedInvoiceItemTempIds;
    return preview.extraItems
        .where((item) => !selectedIds.contains(item.invoiceItemTempId))
        .toList();
  }

  ReviewSummary get displayedSummary {
    final preview = this.preview;
    if (preview == null) {
      return const ReviewSummary(
        matchedItemsCount: 0,
        ambiguousItemsCount: 0,
        unmatchedItemsCount: 0,
        invoiceExtraItemsCount: 0,
      );
    }

    var matchedItemsCount = 0;
    var ambiguousItemsCount = 0;
    var unmatchedItemsCount = 0;

    for (final item in preview.cartItems) {
      switch (item.status) {
        case CartReviewStatus.matched:
          matchedItemsCount += 1;
          break;
        case CartReviewStatus.ambiguous:
          final manualSelection = manualMatches[item.cartItemId];
          if (manualSelection ==
              ClosePurchaseWithNfeUi.ignoreCartItemSelection) {
            unmatchedItemsCount += 1;
          } else if (manualSelection != null) {
            matchedItemsCount += 1;
          } else {
            ambiguousItemsCount += 1;
          }
          break;
        case CartReviewStatus.unmatched:
          unmatchedItemsCount += 1;
          break;
      }
    }

    return ReviewSummary(
      matchedItemsCount: matchedItemsCount,
      ambiguousItemsCount: ambiguousItemsCount,
      unmatchedItemsCount: unmatchedItemsCount,
      invoiceExtraItemsCount: displayedExtraItems.length,
    );
  }

  ClosePurchaseWithNfeState copyWith({
    ClosePurchaseWithNfeStatus? status,
    PurchaseWithNfePreview? preview,
    bool clearPreview = false,
    Map<String, String>? manualMatches,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ClosePurchaseWithNfeState(
      status: status ?? this.status,
      preview: clearPreview ? null : (preview ?? this.preview),
      manualMatches: manualMatches ?? this.manualMatches,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, preview, manualMatches, errorMessage];
}

final class ClosePurchaseWithNfeUi {
  static const String ignoreCartItemSelection = '__ignore_cart_item__';
}
