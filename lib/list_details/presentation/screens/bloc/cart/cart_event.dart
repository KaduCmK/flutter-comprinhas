part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class AddToCart extends CartEvent {
  final String listItemId;
  const AddToCart(this.listItemId);
  @override
  List<Object?> get props => [listItemId];
}

class RemoveFromCart extends CartEvent {
  final String cartItemId;
  const RemoveFromCart(this.cartItemId);
  @override
  List<Object?> get props => [cartItemId];
}

class SetCartMode extends CartEvent {
  final CartMode mode;
  const SetCartMode(this.mode);
  @override
  List<Object?> get props => [mode];
}

class ConfirmPurchase extends CartEvent {}