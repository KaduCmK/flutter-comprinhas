part of 'cart_bloc.dart';

class CartState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<CartItem> cartItems;
  final CartMode cartMode;

  const CartState({
    this.isLoading = false,
    this.error,
    this.cartItems = const [],
    this.cartMode = CartMode.shared,
  });

  CartState copyWith({
    bool? isLoading,
    String? error,
    List<CartItem>? cartItems,
    CartMode? cartMode,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      cartItems: cartItems ?? this.cartItems,
      cartMode: cartMode ?? this.cartMode,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, cartItems, cartMode];
}