class Quadras {
  final int id;
  final int idEstabelecimento;
  final String nome;
  final String tipoQuadra;
  final String preco;

  Quadras({
    required this.id,
    required this.idEstabelecimento,
    required this.nome,
    required this.tipoQuadra,
    required this.preco,
  });

factory Quadras.fromJson(Map<String, dynamic> json) {
  return Quadras(
    id: json['id_quadra'] ?? 0,
    idEstabelecimento: json['id_estabelecimento'] ?? 0,
    nome: json['nome'] ?? "",
    tipoQuadra: json['tipo_quadra'] ?? "",
    preco: json['preco'] ?? "",
  );
}
}