import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

abstract class ListasRepository {
  Future<List<ListaCompra>> getUserLists();
  Future<void> createList(String name);

  Future<List<ListItem>> getListItems(String listId);
  Future<List<Unit>> getUnits();
  Future<void> addItemToList(
    String listId,
    String name,
    num amount,
    String unitId,
  );
}
