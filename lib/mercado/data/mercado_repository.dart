import 'package:flutter/foundation.dart';
import 'package:flutter_comprinhas/shared/entities/mercado.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MercadoProdutoResumo {
  final String id;
  final String nome;
  final double ultimoPreco;
  final DateTime ultimaDataRegistro;

  const MercadoProdutoResumo({
    required this.id,
    required this.nome,
    required this.ultimoPreco,
    required this.ultimaDataRegistro,
  });
}

class MercadoStats {
  final Mercado mercado;
  final int totalNotas;
  final double valorTotalGasto;

  MercadoStats({
    required this.mercado,
    required this.totalNotas,
    required this.valorTotalGasto,
  });
}

class MercadoRepository {
  final SupabaseClient _client;

  MercadoRepository({required SupabaseClient client}) : _client = client;

  Future<void> sendNfe(String nfe) async {
    await _client.functions.invoke('scrape-nfce', body: {'chave_acesso': nfe});
  }

  Future<List<PurchaseHistory>> getNfeHistory() async {
    // Busca notas fiscais, o nome do usuário que enviou, o mercado e os itens da nota com o nome dos produtos
    final response = await _client
        .from('notas_fiscais')
        .select('*, users(*), mercados(*), itens_nota_fiscal(*, produtos(*))')
        .order('data_de_emissao', ascending: false);

    return (response as List)
        .map((json) => PurchaseHistory.fromMap(json))
        .toList();
  }

  Future<List<PurchaseHistory>> getNfeHistoryByMercado(String mercadoId) async {
    final response = await _client
        .from('notas_fiscais')
        .select('*, users(*), mercados(*), itens_nota_fiscal(*, produtos(*))')
        .eq('mercado_id', mercadoId)
        .order('data_de_emissao', ascending: false);

    return (response as List)
        .map((json) => PurchaseHistory.fromMap(json))
        .toList();
  }

  Future<List<MercadoProdutoResumo>> getProductsByMercado(
    String mercadoId,
  ) async {
    final response = await _client
        .from('notas_fiscais')
        .select(
          'data_de_emissao, created_at, itens_nota_fiscal(quantidade, valor_total_item, produtos(id, nome, valor_unitario))',
        )
        .eq('mercado_id', mercadoId)
        .order('data_de_emissao', ascending: false);

    final latestByProduct = <String, MercadoProdutoResumo>{};

    for (final nota in (response as List)) {
      final rawDate = nota['data_de_emissao'] ?? nota['created_at'];
      if (rawDate == null) continue;

      final notaDate = DateTime.parse(rawDate as String);
      final itens = (nota['itens_nota_fiscal'] as List?) ?? const [];

      for (final item in itens) {
        final itemMap = item as Map<String, dynamic>;
        final produto = itemMap['produtos'] as Map<String, dynamic>?;
        if (produto == null) continue;

        final produtoId = produto['id'] as String?;
        final produtoNome = produto['nome'] as String?;
        if (produtoId == null || produtoNome == null || produtoNome.isEmpty) {
          continue;
        }

        final quantidade = (itemMap['quantidade'] as num?)?.toDouble() ?? 0;
        final valorTotal =
            (itemMap['valor_total_item'] as num?)?.toDouble() ?? 0;
        final ultimoPreco =
            quantidade > 0
                ? valorTotal / quantidade
                : (produto['valor_unitario'] as num?)?.toDouble();

        if (ultimoPreco == null) continue;

        final current = latestByProduct[produtoId];
        if (current == null || notaDate.isAfter(current.ultimaDataRegistro)) {
          latestByProduct[produtoId] = MercadoProdutoResumo(
            id: produtoId,
            nome: produtoNome,
            ultimoPreco: ultimoPreco,
            ultimaDataRegistro: notaDate,
          );
        }
      }
    }

    final produtos =
        latestByProduct.values.toList()..sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );

    return produtos;
  }

  Future<List<MercadoStats>> getTopMercados() async {
    // Busca todos os mercados vinculados às notas fiscais do usuário logado e agrupa
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // O Supabase postgrest nao tem um GROUP BY nativo muito flexivel, entao buscamos as notas e agrupamos no Dart.
    // Uma alternative seria uma Function/View no banco, mas faremos no Dart por enquanto.
    final response = await _client
        .from('notas_fiscais')
        .select('valor_total, mercados(*)')
        .eq('user_id', userId);

    final mapStats = <String, MercadoStats>{};

    for (final nota in (response as List)) {
      if (nota['mercados'] == null) continue;

      final mercado = Mercado.fromMap(nota['mercados']);
      final valor = (nota['valor_total'] as num).toDouble();

      if (mapStats.containsKey(mercado.id)) {
        final current = mapStats[mercado.id]!;
        mapStats[mercado.id] = MercadoStats(
          mercado: mercado,
          totalNotas: current.totalNotas + 1,
          valorTotalGasto: current.valorTotalGasto + valor,
        );
      } else {
        mapStats[mercado.id] = MercadoStats(
          mercado: mercado,
          totalNotas: 1,
          valorTotalGasto: valor,
        );
      }
    }

    final statsList = mapStats.values.toList();
    statsList.sort((a, b) => b.valorTotalGasto.compareTo(a.valorTotalGasto));

    return statsList;
  }

  Future<MercadoStats?> getMercadoStatsById(String mercadoId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('notas_fiscais')
        .select('valor_total, mercados(*)')
        .eq('user_id', userId)
        .eq('mercado_id', mercadoId);

    if ((response as List).isEmpty) return null;

    double totalGasto = 0;
    for (final nota in response) {
      totalGasto += (nota['valor_total'] as num).toDouble();
    }

    return MercadoStats(
      mercado: Mercado.fromMap(response[0]['mercados']),
      totalNotas: response.length,
      valorTotalGasto: totalGasto,
    );
  }

  Future<List<Map<String, dynamic>>> getProductPriceHistory(
    String produtoId,
  ) async {
    try {
      final response = await _client
          .from('itens_nota_fiscal')
          .select(
            'quantidade, valor_total_item, notas_fiscais(data_de_emissao)',
          )
          .eq('produto_id', produtoId)
          .order(
            'data_de_emissao',
            referencedTable: 'notas_fiscais',
            ascending: true,
          );

      return (response as List).map((item) {
        final double total = (item['valor_total_item'] as num).toDouble();
        final double qtd = (item['quantidade'] as num).toDouble();
        final notaFiscal = item['notas_fiscais'];

        if (notaFiscal == null || notaFiscal['data_de_emissao'] == null) {
          return {
            'data': DateTime.now(),
            'preco_unitario': qtd > 0 ? total / qtd : 0.0,
          };
        }

        return {
          'data': DateTime.parse(notaFiscal['data_de_emissao']),
          'preco_unitario': qtd > 0 ? total / qtd : 0.0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar histórico de preços: $e');
      rethrow;
    }
  }
}
