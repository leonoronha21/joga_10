import 'package:joga_10/db/row_utils.dart';

/// Situação da amizade entre o usuário logado e outro usuário.
enum StatusAmizade { nenhuma, pendenteEnviado, pendenteRecebido, amigos }

/// Pedido de amizade recebido (para a tela de solicitações).
class PedidoAmizade {
  final int amizadeId;
  final int usuarioId;
  final String nome;
  final String email;

  PedidoAmizade({
    required this.amizadeId,
    required this.usuarioId,
    required this.nome,
    required this.email,
  });

  factory PedidoAmizade.fromRow(Map<String, dynamic> row) {
    return PedidoAmizade(
      amizadeId: asInt(row['amizade_id']),
      usuarioId: asInt(row['usuario_id']),
      nome: (row['nome'] as String?) ?? 'Usuário',
      email: (row['email'] as String?) ?? '',
    );
  }
}

/// Resultado de busca de usuários, já com a relação em relação ao logado.
class UsuarioBusca {
  final int id;
  final String nome;
  final String email;
  final StatusAmizade status;
  final int? amizadeId;

  UsuarioBusca({
    required this.id,
    required this.nome,
    required this.email,
    required this.status,
    this.amizadeId,
  });
}
