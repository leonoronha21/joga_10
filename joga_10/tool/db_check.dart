// Verificação headless da camada de dados contra o Postgres real.
// Roda no host (localhost), espelhando o SQL dos repositórios.
//   dart run tool/db_check.dart
import 'dart:typed_data';

import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

Future<void> main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'joga10',
      username: 'joga10_app',
      password: 'joga10_app_pwd',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );
  print('✓ Conectado ao Postgres');

  // 1) Login (mesma lógica do UsuarioRepository.login)
  final r = await conn.execute(
    Sql.named('SELECT * FROM usuario WHERE email = @email'),
    parameters: {'email': 'teste@joga10.com'},
  );
  if (r.isEmpty) {
    print('✗ Usuário de teste não encontrado');
  } else {
    final row = r.first.toColumnMap();
    final ok = BCrypt.checkpw('123456', row['senha_hash'] as String);
    print('✓ Login teste@joga10.com / 123456 -> ${ok ? "OK" : "FALHOU"}');
    print('  nome: ${row['primeiro_nome']} | role: ${row['role']}');
  }

  // 2) Partidas com JOIN (PartidaRepository.listarTodas)
  final partidas = await conn.execute('''
    SELECT p.*, q.nome AS quadra_nome, e.nome AS estabelecimento_nome
    FROM partida p
    LEFT JOIN quadra q          ON q.id = p.id_quadra
    LEFT JOIN estabelecimento e ON e.id = p.id_estabelecimento
    ORDER BY p.data_hora DESC
  ''');
  print('✓ Partidas: ${partidas.length}');
  for (final p in partidas) {
    final m = p.toColumnMap();
    final membros = await conn.execute(
      Sql.named('SELECT count(*) c FROM partida_membro WHERE partida_id = @id'),
      parameters: {'id': m['id']},
    );
    final qtd = membros.first.toColumnMap()['c'];
    print('  #${m['id']} ${m['quadra_nome']} @ ${m['estabelecimento_nome']} '
        '| ${m['status']} | ${m['data_hora']} | preco=${m['preco']} | membros=$qtd');
  }

  // 3) Quadras (QuadraRepository.listarTodas)
  final quadras = await conn.execute('SELECT * FROM quadra ORDER BY nome');
  print('✓ Quadras: ${quadras.length}');
  for (final q in quadras) {
    final m = q.toColumnMap();
    print('  ${m['nome']} (${m['tipo_quadra']}) - preco=${m['preco']} '
        '[tipo dart: ${m['preco'].runtimeType}]');
  }

  // 4) Social: feed do usuário de teste
  final me = (await conn.execute(
    Sql.named("SELECT id FROM usuario WHERE email = 'teste@joga10.com'"),
  )).first.toColumnMap()['id'] as int;

  final feed = await conn.execute(
    Sql.named('''
      SELECT p.id, p.texto,
             (SELECT count(*) FROM curtida c WHERE c.postagem_id = p.id) AS curtidas,
             EXISTS(SELECT 1 FROM curtida c WHERE c.postagem_id = p.id AND c.usuario_id = @me) AS curtiu_eu,
             (SELECT count(*) FROM comentario cm WHERE cm.postagem_id = p.id) AS comentarios
      FROM postagem p
      WHERE p.autor_id = @me
      ORDER BY p.criado_em DESC
    '''),
    parameters: {'me': me},
  );
  print('✓ Feed do usuário de teste: ${feed.length} post(s)');
  for (final p in feed) {
    final m = p.toColumnMap();
    print('  #${m['id']} "${m['texto']}" curtidas=${m['curtidas']} '
        'curtiu_eu=${m['curtiu_eu']} comentarios=${m['comentarios']}');
  }

  // 5) Insert de foto (bytea) e leitura de volta
  final bytes = [137, 80, 78, 71, 13, 10, 26, 10]; // assinatura PNG (fake)
  final ins = await conn.execute(
    Sql.named('INSERT INTO postagem (autor_id, texto, foto) '
        'VALUES (@a, @t, @f) RETURNING id'),
    parameters: {
      'a': me,
      't': 'teste de foto',
      'f': TypedValue(Type.byteArray, Uint8List.fromList(bytes)),
    },
  );
  final postId = ins.first.toColumnMap()['id'] as int;
  final back = await conn.execute(
    Sql.named('SELECT foto FROM postagem WHERE id = @id'),
    parameters: {'id': postId},
  );
  final foto = back.first.toColumnMap()['foto'];
  print('✓ Foto bytea round-trip: ${foto.runtimeType}, '
      '${(foto as List).length} bytes (esperado 8)');
  // limpa o post de teste
  await conn.execute(
    Sql.named('DELETE FROM postagem WHERE id = @id'),
    parameters: {'id': postId},
  );

  await conn.close();
  print('✓ Verificação concluída');
}
