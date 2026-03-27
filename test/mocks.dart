import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockListasRepository extends Mock implements ListasRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGotrueClient extends Mock implements GoTrueClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class FakeRealtimeChannel extends Fake implements RealtimeChannel {}
