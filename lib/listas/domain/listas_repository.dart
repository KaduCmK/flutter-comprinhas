import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

abstract class ListasRepository {
  Future<List<ListaCompra>> getUserLists();
  Future<void> createList(String name);
  Future<void> joinList(String listId);
  Future<ListaCompra> getListById(String listId);

  Future<List<ListItem>> getListItems(String listId);
  Future<List<Unit>> getUnits();
  Future<void> addItemToList(
    String listId,
    String name,
    num amount,
    String unitId,
  );
  Future<void> removeItemFromList(String itemId);

  // funcionalidades de carrinho
  Future<List<CartItem>> getCartItems(String listId);
  Future<void> addItemToCart(String listItemId);
  Future<void> removeItemFromCart(String cartItemId);
  Future<void> setCartMode(String listId, CartMode mode);
}
