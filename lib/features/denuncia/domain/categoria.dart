/// Categoria de resíduo, da tabela `categoria_residuo`.
class Categoria {
  final String id;
  final String nome;
  final String? icone;

  const Categoria({
    required this.id,
    required this.nome,
    this.icone,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id_categoria'] as String,
      nome: json['nome'] as String,
      icone: json['icone'] as String?,
    );
  }
}
