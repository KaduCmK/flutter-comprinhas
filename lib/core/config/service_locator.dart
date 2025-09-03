import 'package:flutter_comprinhas/listas/data/listas_repository_impl.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

void configureServiceLocator() {
  sl.registerLazySingleton<ListasRepository>(
    () => ListasRepositoryImpl(client: Supabase.instance.client),
  );
  sl.registerLazySingleton<MercadoRepository>(
    () => MercadoRepository(client: Supabase.instance.client),
  );
}
