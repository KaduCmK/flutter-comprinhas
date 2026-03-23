import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MercadoRepository {
  final SupabaseClient _client;

  MercadoRepository({required SupabaseClient client}) : _client = client;

  Future<void> sendNfe(String nfe) async {
    await _client.functions.invoke('scrape-nfce', body: {'chave_acesso': nfe});
  }

  Future<List<PurchaseHistory>> getNfeHistory() async {
    // Busca notas fiscais, o nome do usuário que enviou e os itens da nota com o nome dos produtos
    final response = await _client
        .from('notas_fiscais')
        .select('*, users(*), itens_nota_fiscal(*, produtos(*))')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PurchaseHistory.fromMap(json))
        .toList();
  }
}
