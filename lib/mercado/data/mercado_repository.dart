import 'package:supabase_flutter/supabase_flutter.dart';

class MercadoRepository {
  final SupabaseClient _client;

  MercadoRepository({required SupabaseClient client}) : _client = client;

  Future<void> sendNfe(String nfe) async {
    await _client.functions.invoke('scrape-nfce', body: {'chave_acesso': nfe});
  }
}
