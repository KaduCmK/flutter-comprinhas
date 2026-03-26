import 'package:equatable/equatable.dart';

class Mercado extends Equatable {
  final String id;
  final String nome;
  final String? cnpj;
  final String? endereco;

  const Mercado({
    required this.id,
    required this.nome,
    this.cnpj,
    this.endereco,
  });

  factory Mercado.fromMap(Map<String, dynamic> map) {
    return Mercado(
      id: map['id'] as String,
      nome: map['nome'] as String,
      cnpj: map['cnpj'] as String?,
      endereco: map['endereco'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, nome, cnpj, endereco];
}
