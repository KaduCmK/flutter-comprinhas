import 'dart:io';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/product_match.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

abstract class ListasRepository {
  Future<List<ListaCompra>> getUserLists();
  Future<String> upsertList(String name, {String? listId, String? backgroundImageUrl});
  Future<String?> uploadBackgroundImage(File imageFile, String listId);
  Future<void> deleteList(String listId);
  Future<void> joinList(String listId);
  Future<ListaCompra> getListById(String listId);
  Future<void> togglePriceForecast(String listId, bool previousValue);

  Future<List<ListItem>> getListItems(String listId);
  Future<List<Unit>> getUnits();
  Future<void> addItemToList(
    String listId,
    String name,
    num amount,
    String unitId,
  );
  Future<Map<String, dynamic>> parseNaturalLanguageItem(
    String query,
    List<Unit> units,
  );
  Future<void> removeItemFromList(String itemId);

  Future<void> sugerirPreco(ListItem item);

  Future<void> updatePrecoSugerido(String itemId, num price);

  Future<List<ProductMatch>> getProductMatches(String listItemId);

  // funcionalidades de carrinho
  Future<List<CartItem>> getCartItems(String? listId);
  Future<void> addItemToCart(String listItemId);
  Future<void> removeItemFromCart(String cartItemId);
  Future<void> setCartMode(String listId, CartMode mode);
  Future<void> confirmPurchase(List<String> cartItemIds);

  // historico
  Future<List<PurchaseHistory>> getPurchaseHistory(String listId);
}
