import 'package:flutter_comprinhas/core/config/app_settings_service.dart';
import 'package:flutter_comprinhas/core/config/messaging_token_source.dart';
import 'package:flutter_comprinhas/core/config/notification_service.dart';
import 'package:flutter_comprinhas/core/config/push_token_sync_service.dart';
import 'package:flutter_comprinhas/listas/data/listas_repository_impl.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_geocoding_service.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_navigation_service.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

void configureServiceLocator() {
  sl.registerLazySingleton<AppSettingsService>(() => AppSettingsService());
  sl.registerLazySingleton<MessagingTokenSource>(
    () => FirebaseMessagingTokenSource(),
  );
  sl.registerLazySingleton<ListasRepository>(
    () => ListasRepositoryImpl(client: Supabase.instance.client),
  );
  sl.registerLazySingleton<MercadoRepository>(
    () => MercadoRepository(client: Supabase.instance.client),
  );
  sl.registerLazySingleton<MercadoGeocodingService>(
    () => MercadoGeocodingService(),
  );
  sl.registerLazySingleton<MercadoNavigationService>(
    () => MercadoNavigationService(),
  );

  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<PushTokenSyncService>(
    () => PushTokenSyncService(
      client: Supabase.instance.client,
      messagingTokenSource: sl(),
    ),
  );
}
