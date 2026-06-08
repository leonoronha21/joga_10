import 'package:joga_10/model/Monetizacao.dart';
import 'package:joga_10/model/Rateio.dart';

abstract interface class MonetizacaoRepositoryContract {
  Future<PartidaRateio?> buscarRateioPorPartida(int partidaId);

  Future<PartidaRateio> criarOuAtualizarRateio({
    required int partidaId,
    required double valorQuadra,
    required double taxaPercentual,
  });

  Future<void> atualizarStatusCobranca(int cobrancaId, String status);

  Future<void> fecharRateio(int rateioId);

  Future<GamificacaoUsuario> buscarGamificacao(int usuarioId);

  Future<List<PlanoAssinatura>> listarPlanos();

  Future<AssinaturaUsuario?> buscarAssinatura(int usuarioId);

  Future<void> ativarTestePro(int usuarioId);
}
