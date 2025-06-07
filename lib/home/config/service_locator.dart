import 'package:flutter_comprinhas/listas/data/listas_repository_impl.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void configureServiceLocator() {
  sl.registerLazySingleton<ListasRepository>(() => ListasRepositoryImpl());
}
