part of 'global_cart_bloc.dart';

abstract class GlobalCartEvent extends Equatable {
  const GlobalCartEvent();

  @override
  List<Object> get props => [];
}

class LoadGlobalCartEvent extends GlobalCartEvent {}
