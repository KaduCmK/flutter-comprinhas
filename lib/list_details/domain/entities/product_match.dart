import 'package:equatable/equatable.dart';

class ProductMatch extends Equatable {
  final String productName;
  final num? price;
  final double similarityScore;

  const ProductMatch({
    required this.productName,
    this.price,
    required this.similarityScore,
  });

  factory ProductMatch.fromMap(Map<String, dynamic> map) {
    // O Supabase retorna o join como um objeto aninhado com o nome da tabela/relação
    // Geralmente no singular se for uma relação 1:1
    final produto =
        map['produtos'] as Map<String, dynamic>? ??
        map['produto'] as Map<String, dynamic>?;

    if (produto == null) {
      throw Exception('Dados do produto não encontrados no mapa: $map');
    }

    return ProductMatch(
      productName: produto['nome'] as String,
      price: produto['valor_unitario'] as num?,
      similarityScore: (map['similarity_score'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [productName, price, similarityScore];
}
