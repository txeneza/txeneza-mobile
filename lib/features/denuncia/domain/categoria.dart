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

  /// Categorias padrão para fallback offline quando a cache estiver vazia.
  static const List<Categoria> defaultOfflineCategorias = [
    Categoria(id: 'temp_organico', nome: 'Orgânico', icone: 'leaf'),
    Categoria(id: 'temp_plastico', nome: 'Plástico', icone: 'recycle'),
    Categoria(id: 'temp_entulho', nome: 'Entulho', icone: 'hammer'),
    Categoria(id: 'temp_vidro', nome: 'Vidro', icone: 'wine'),
    Categoria(id: 'temp_metal', nome: 'Metal', icone: 'bolt'),
    Categoria(id: 'temp_papel', nome: 'Papel', icone: 'file-text'),
    Categoria(id: 'temp_eletronico', nome: 'Eletrónico', icone: 'cpu'),
    Categoria(id: 'temp_outro', nome: 'Outro', icone: 'circle-help'),
  ];
}

