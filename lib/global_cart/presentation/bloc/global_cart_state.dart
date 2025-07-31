part of 'global_cart_bloc.dart';

class GlobalCartState extends Equatable {
  final List<CartItem> cartItems;
  final bool isLoading;
  final String? error;

  const GlobalCartState({
    this.cartItems = const [],
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [cartItems, isLoading, error];
}
