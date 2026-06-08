import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/repositories/monetizacao_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/repositories/postagem_repository.dart';
import 'package:joga_10/services/sessao.dart';

void main() {
  test('admin local carrega dados ficticios sem depender do banco', () async {
    SharedPreferences.setMockInitialValues({});
    await Sessao.instance.salvar(
      Usuario(
        id: 0,
        primeiroNome: 'Admin',
        segundoNome: 'Local',
        email: 'admin',
        role: 'ADMIN',
      ),
    );

    final partidas = await PartidaRepository().listarPorUsuario(0);
    final locais = await EstabelecimentoRepository().listarTodos();
    final feed = await PostagemRepository().listarFeed(0);
    final ligas = await CampeonatoRepository().listarLigas();
    final rateio =
        await MonetizacaoRepository().buscarRateioPorPartida(partidas.first.id);

    expect(partidas, isNotEmpty);
    expect(locais, isNotEmpty);
    expect(feed, isNotEmpty);
    expect(ligas, isNotEmpty);
    expect(rateio, isNotNull);
  });
}
