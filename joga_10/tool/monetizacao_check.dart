import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Rateio.dart';
import 'package:joga_10/repositories/monetizacao_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';

Future<void> main() async {
  final partidaRepo = PartidaRepository();
  final monetizacaoRepo = MonetizacaoRepository();

  try {
    final partidas = await partidaRepo.listarTodas();
    if (partidas.isEmpty) {
      throw StateError('Nenhuma partida encontrada para testar.');
    }

    final partida = partidas.first;
    final rateio = await monetizacaoRepo.criarOuAtualizarRateio(
      partidaId: partida.id,
      valorQuadra: partida.preco,
    );

    if (rateio.cobrancas.length != partida.membros.length) {
      throw StateError('Cobrancas nao batem com membros da partida.');
    }

    final primeira = rateio.cobrancas.first;
    await monetizacaoRepo.atualizarStatusCobranca(
      primeira.id,
      CobrancaStatus.pago,
    );

    if (primeira.idUser != null) {
      final gamificacao =
          await monetizacaoRepo.buscarGamificacao(primeira.idUser!);
      if (gamificacao.pagamentosEmDia < 1) {
        throw StateError('Gamificacao nao registrou pagamento.');
      }
    }

    await monetizacaoRepo.atualizarStatusCobranca(
      primeira.id,
      CobrancaStatus.pendente,
    );

    await monetizacaoRepo.ativarTestePro(partida.organizadorId);
    final assinatura =
        await monetizacaoRepo.buscarAssinatura(partida.organizadorId);
    if (assinatura?.plano.codigo != 'PRO' || assinatura?.ativa != true) {
      throw StateError('Assinatura Pro local nao foi ativada.');
    }

    print('Monetizacao OK');
    print('Partida: ${partida.id}');
    print('Cobrancas: ${rateio.cobrancas.length}');
    print('Valor por jogador: ${primeira.valorTotal.toStringAsFixed(2)}');
    print('Plano demo: ${assinatura!.plano.nome}');
  } finally {
    await AppDatabase.instance.close();
  }
}
