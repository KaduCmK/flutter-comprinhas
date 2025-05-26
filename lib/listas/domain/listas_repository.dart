import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';

abstract class ListasRepository {
  Future<List<ListaCompra>> getUserLists();
  Future<void> createList(String name);
}