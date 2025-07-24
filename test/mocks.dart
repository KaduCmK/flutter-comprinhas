import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// mocks do supabase
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsCliente extends Mock implements FunctionsClient {}

class MockPostgrestClient extends Mock implements PostgrestClient {}

class MockUser extends Mock implements User {}

class MockListasRepository extends Mock implements ListasRepository {}
