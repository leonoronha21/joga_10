import 'dart:typed_data';

import 'package:joga_10/domain/services/calculadora_rateio.dart';
import 'package:joga_10/model/Amizade.dart';
import 'package:joga_10/model/Cartao.dart';
import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/ClubeJogador.dart';
import 'package:joga_10/model/Comentario.dart';
import 'package:joga_10/model/Confronto.dart';
import 'package:joga_10/model/Contratacao.dart';
import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/model/Goleiro.dart';
import 'package:joga_10/model/Liga.dart';
import 'package:joga_10/model/LinhaClassificacao.dart';
import 'package:joga_10/model/Monetizacao.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/model/Postagem.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/model/Rateio.dart';
import 'package:joga_10/model/Usuario.dart';

class LocalDemoData {
  LocalDemoData._() {
    _inicializar();
  }

  static final LocalDemoData instance = LocalDemoData._();

  static const adminId = 0;
  static const _calculadora = CalculadoraRateio();

  final List<Partida> partidas = [];
  final List<Postagem> postagens = [];
  final List<Cartao> cartoes = [];
  final Map<int, List<Comentario>> comentarios = {};
  final Map<int, PartidaRateio> rateios = {};
  final Set<int> _amigosIds = {-11, -12, -13};
  final Map<int, StatusAmizade> _statusAmizades = {
    -14: StatusAmizade.pendenteRecebido,
  };

  Uint8List? fotoAdmin;
  String? fotoAdminUrl;
  AssinaturaUsuario? assinatura;
  Goleiro? perfilGoleiroAdmin;
  int _proximoId = -1000;

  int novoId() => _proximoId--;

  final usuarios = <Usuario>[
    Usuario(
      id: adminId,
      primeiroNome: 'Admin',
      segundoNome: 'Local',
      email: 'admin',
      cidade: 'Sao Paulo',
      bairro: 'Vila Mariana',
      contato: '(11) 99999-0001',
      role: 'ADMIN',
    ),
    Usuario(
      id: -11,
      primeiroNome: 'Bruno',
      segundoNome: 'Silva',
      email: 'bruno@demo.joga10',
      cidade: 'Sao Paulo',
    ),
    Usuario(
      id: -12,
      primeiroNome: 'Carla',
      segundoNome: 'Mendes',
      email: 'carla@demo.joga10',
      cidade: 'Sao Paulo',
    ),
    Usuario(
      id: -13,
      primeiroNome: 'Diego',
      segundoNome: 'Costa',
      email: 'diego@demo.joga10',
      cidade: 'Sao Paulo',
    ),
    Usuario(
      id: -14,
      primeiroNome: 'Ana',
      segundoNome: 'Lima',
      email: 'ana@demo.joga10',
      cidade: 'Sao Paulo',
    ),
    Usuario(
      id: -15,
      primeiroNome: 'Rafael',
      segundoNome: 'Souza',
      email: 'rafael@demo.joga10',
      cidade: 'Porto Alegre',
    ),
  ];

  final estabelecimentos = <Estabelecimentos>[
    Estabelecimentos(
      id: -101,
      nome: 'Arena Joga10 Moinhos',
      cidade: 'Porto Alegre',
      bairro: 'Moinhos de Vento',
      rua: 'Rua Padre Chagas',
      numero: '100',
      telefone: '(51) 3333-1010',
      horaAbertura: '08:00',
      horaFechamento: '23:30',
      status: 1,
      latitude: -30.0247,
      longitude: -51.2030,
    ),
    Estabelecimentos(
      id: -102,
      nome: 'Centro Esportivo Marinha do Brasil',
      cidade: 'Porto Alegre',
      bairro: 'Praia de Belas',
      rua: 'Av. Edvaldo Pereira Paiva',
      numero: '200',
      telefone: '(51) 3333-2020',
      horaAbertura: '07:00',
      horaFechamento: '22:00',
      status: 1,
      latitude: -30.0577,
      longitude: -51.2370,
    ),
    Estabelecimentos(
      id: -103,
      nome: 'Quadras Parque da Redenção',
      cidade: 'Porto Alegre',
      bairro: 'Bom Fim',
      rua: 'Av. João Pessoa',
      numero: '88',
      telefone: '(51) 3333-3030',
      horaAbertura: '09:00',
      horaFechamento: '00:00',
      status: 1,
      latitude: -30.0395,
      longitude: -51.2160,
    ),
  ];

  final quadras = <Quadras>[
    Quadras(
      id: -201,
      idEstabelecimento: -101,
      nome: 'Society Principal',
      tipoQuadra: 'Futebol Society',
      preco: 180,
    ),
    Quadras(
      id: -202,
      idEstabelecimento: -101,
      nome: 'Quadra de Futsal',
      tipoQuadra: 'Futsal',
      preco: 140,
    ),
    Quadras(
      id: -203,
      idEstabelecimento: -102,
      nome: 'Campo 7',
      tipoQuadra: 'Futebol Society',
      preco: 210,
    ),
    Quadras(
      id: -204,
      idEstabelecimento: -102,
      nome: 'Basquete Coberto',
      tipoQuadra: 'Basquete',
      preco: 110,
    ),
    Quadras(
      id: -205,
      idEstabelecimento: -103,
      nome: 'Areia Premium',
      tipoQuadra: 'Volei',
      preco: 130,
    ),
  ];

  final ligas = <Liga>[
    Liga(
        id: -301,
        nome: 'Liga de Bairro Demo',
        cidade: 'Sao Paulo',
        totalTimes: 3),
  ];

  final clubes = <Clube>[
    Clube(
        id: -311,
        nome: 'Joga10 FC',
        cidade: 'Sao Paulo',
        cor: '#1B3A6B',
        donoId: adminId),
    Clube(id: -312, nome: 'Vila United', cidade: 'Sao Paulo', cor: '#C0392B'),
    Clube(id: -313, nome: 'Resenha City', cidade: 'Sao Paulo', cor: '#27AE60'),
  ];

  final elencos = <int, List<ClubeJogador>>{
    -311: [
      ClubeJogador(
          id: -401,
          clubeId: -311,
          nome: 'Admin Local',
          posicao: 'Meia',
          numero: 10),
      ClubeJogador(
          id: -402,
          clubeId: -311,
          nome: 'Bruno Silva',
          posicao: 'Atacante',
          numero: 9),
      ClubeJogador(
          id: -403,
          clubeId: -311,
          nome: 'Carla Mendes',
          posicao: 'Goleiro',
          numero: 1),
    ],
    -312: [
      ClubeJogador(
          id: -404,
          clubeId: -312,
          nome: 'Diego Costa',
          posicao: 'Atacante',
          numero: 7),
      ClubeJogador(
          id: -405,
          clubeId: -312,
          nome: 'Ana Lima',
          posicao: 'Meia',
          numero: 8),
    ],
    -313: [
      ClubeJogador(
          id: -406,
          clubeId: -313,
          nome: 'Rafael Demo',
          posicao: 'Zagueiro',
          numero: 4),
    ],
  };

  final confrontos = <Confronto>[
    Confronto(
      id: -501,
      clubeCasaId: -311,
      clubeCasaNome: 'Joga10 FC',
      clubeCasaCor: '#1B3A6B',
      clubeVisitanteId: -312,
      clubeVisitanteNome: 'Vila United',
      clubeVisitanteCor: '#C0392B',
      dataHora: DateTime.now().subtract(const Duration(days: 7)),
      tipo: 'OFICIAL',
      local: 'Arena Joga10 Paulista',
      status: ConfrontoStatus.realizado,
      placarCasa: 4,
      placarVisitante: 2,
    ),
    Confronto(
      id: -502,
      clubeCasaId: -313,
      clubeCasaNome: 'Resenha City',
      clubeCasaCor: '#27AE60',
      clubeVisitanteId: -311,
      clubeVisitanteNome: 'Joga10 FC',
      clubeVisitanteCor: '#1B3A6B',
      dataHora: DateTime.now().add(const Duration(days: 6)),
      tipo: 'OFICIAL',
      local: 'Centro Esportivo Ibirapuera',
      status: ConfrontoStatus.agendado,
    ),
  ];

  final goleiros = <Goleiro>[
    Goleiro(
      id: -601,
      usuarioId: -21,
      nome: 'Marcos Paredao',
      cidade: 'Sao Paulo',
      precoJogo: 80,
      nivel: 5,
      observacao: 'Disponivel a noite e aos finais de semana.',
      contato: '(11) 98888-1001',
    ),
    Goleiro(
      id: -602,
      usuarioId: -22,
      nome: 'Luana Muralha',
      cidade: 'Sao Paulo',
      precoJogo: 70,
      nivel: 4,
      observacao: 'Futsal e society.',
      contato: '(11) 98888-1002',
    ),
  ];

  final solicitacoesGoleiro = <Contratacao>[
    Contratacao(
      id: -701,
      goleiroId: -700,
      partidaId: -801,
      solicitanteId: -11,
      status: ContratacaoStatus.pendente,
      valor: 75,
      criadoEm: DateTime.now().subtract(const Duration(hours: 3)),
      solicitanteNome: 'Bruno Silva',
      partidaQuadra: 'Society Principal',
      partidaData: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  final planos = <PlanoAssinatura>[
    PlanoAssinatura(
      id: -1,
      codigo: 'FREE',
      nome: 'Joga10 Free',
      descricao: 'Partidas, convites e rateios liberados sem taxa.',
      precoMensal: 0,
    ),
    PlanoAssinatura(
      id: -2,
      codigo: 'PRO',
      nome: 'Joga10 Pro',
      descricao: 'Campeonatos e rateios sem taxa.',
      precoMensal: 14.90,
    ),
  ];

  void _inicializar() {
    final agora = DateTime.now();
    partidas.addAll([
      Partida(
        id: -801,
        idEstabelecimento: -101,
        idQuadra: -201,
        organizadorId: adminId,
        organizadorNome: 'Admin Local',
        duracao: '1h',
        dataHora: agora.add(const Duration(days: 3, hours: 2)),
        status: PartidaStatus.agendada,
        preco: 180,
        formato: '5x5',
        quadraNome: 'Society Principal',
        estabelecimentoNome: 'Arena Joga10 Paulista',
        membros: [
          _membro(-811, adminId, Equipe.time1, 'Admin Local', capitao: true),
          _membro(-812, -11, Equipe.time1, 'Bruno Silva'),
          _membro(-813, -12, Equipe.time1, 'Carla Mendes'),
          _membro(-814, -13, Equipe.time2, 'Diego Costa', capitao: true),
          _membro(-815, -14, Equipe.time2, 'Ana Lima'),
        ],
      ),
      Partida(
        id: -802,
        idEstabelecimento: -102,
        idQuadra: -203,
        organizadorId: -11,
        organizadorNome: 'Bruno Silva',
        duracao: '1h30',
        dataHora: agora.add(const Duration(days: 9)),
        status: PartidaStatus.agendada,
        preco: 210,
        formato: '7x7',
        quadraNome: 'Campo 7',
        estabelecimentoNome: 'Centro Esportivo Ibirapuera',
        membros: [
          _membro(-821, adminId, Equipe.time2, 'Admin Local', capitao: true),
          _membro(-822, -11, Equipe.time1, 'Bruno Silva', capitao: true),
          _membro(-823, -13, Equipe.time1, 'Diego Costa'),
        ],
      ),
      Partida(
        id: -803,
        idEstabelecimento: -101,
        idQuadra: -202,
        organizadorId: adminId,
        organizadorNome: 'Admin Local',
        duracao: '1h',
        dataHora: agora.subtract(const Duration(days: 5)),
        status: PartidaStatus.finalizada,
        preco: 140,
        placarTime1: 6,
        placarTime2: 4,
        quadraNome: 'Quadra de Futsal',
        estabelecimentoNome: 'Arena Joga10 Paulista',
        membros: [
          _membro(-831, adminId, Equipe.time1, 'Admin Local', gols: 2),
          _membro(-832, -11, Equipe.time1, 'Bruno Silva', gols: 3),
          _membro(-833, -12, Equipe.time1, 'Carla Mendes', gols: 1),
          _membro(-834, -13, Equipe.time2, 'Diego Costa', gols: 2),
          _membro(-835, -14, Equipe.time2, 'Ana Lima', gols: 2),
        ],
      ),
      Partida(
        id: -804,
        idEstabelecimento: -103,
        idQuadra: -205,
        organizadorId: adminId,
        organizadorNome: 'Admin Local',
        duracao: '1h30',
        dataHora: agora.subtract(const Duration(days: 2)),
        status: PartidaStatus.finalizada,
        preco: 130,
        modalidade: ModalidadePartida.volei,
        formato: '2x2',
        placarTime1: 2,
        placarTime2: 1,
        quadraNome: 'Areia Premium',
        estabelecimentoNome: 'Quadras Parque da Redenção',
        membros: [
          _membro(-841, adminId, Equipe.time1, 'Admin Local'),
          _membro(-842, -12, Equipe.time1, 'Carla Mendes'),
          _membro(-843, -11, Equipe.time2, 'Bruno Silva'),
          _membro(-844, -14, Equipe.time2, 'Ana Lima'),
        ],
      ),
    ]);

    postagens.addAll([
      Postagem(
        id: -901,
        autorId: -11,
        autorNome: 'Bruno Silva',
        texto: 'Partida confirmada para sexta! Quem vai levar a bola?',
        partidaId: -801,
        visibilidade: VisibilidadePostagem.publico,
        criadoEm: agora.subtract(const Duration(hours: 2)),
        curtidas: 8,
        curtiuEu: true,
        comentarios: 2,
      ),
      Postagem(
        id: -902,
        autorId: adminId,
        autorNome: 'Admin Local',
        texto: 'Que jogo! Vitoria por 6 a 4 e resenha garantida.',
        partidaId: -803,
        tipo: TipoPostagem.atividade,
        visibilidade: VisibilidadePostagem.publico,
        atividadeModalidade: ModalidadePartida.futebol,
        atividadeLocal: 'Quadra de Futsal',
        atividadeDataHora: agora.subtract(const Duration(days: 5)),
        atividadeDuracao: '1h',
        atividadePlacarEquipeA: 6,
        atividadePlacarEquipeB: 4,
        atividadeParticipantes: 5,
        criadoEm: agora.subtract(const Duration(days: 4)),
        curtidas: 14,
        comentarios: 1,
      ),
      Postagem(
        id: -903,
        autorId: -12,
        autorNome: 'Carla Mendes',
        texto: 'Goleira da rodada e sem tomar gol no segundo tempo.',
        visibilidade: VisibilidadePostagem.amigos,
        criadoEm: agora.subtract(const Duration(days: 6)),
        curtidas: 21,
        comentarios: 3,
      ),
      Postagem(
        id: -904,
        autorId: adminId,
        autorNome: 'Admin Local',
        texto: 'Vôlei na areia e jogo decidido no terceiro set!',
        partidaId: -804,
        tipo: TipoPostagem.atividade,
        visibilidade: VisibilidadePostagem.publico,
        atividadeModalidade: ModalidadePartida.volei,
        atividadeLocal: 'Areia Premium',
        atividadeDataHora: agora.subtract(const Duration(days: 2)),
        atividadeDuracao: '1h30',
        atividadePlacarEquipeA: 2,
        atividadePlacarEquipeB: 1,
        atividadeParticipantes: 4,
        criadoEm: agora.subtract(const Duration(days: 1, hours: 18)),
        curtidas: 19,
        comentarios: 2,
      ),
    ]);

    comentarios[-901] = [
      Comentario(
        id: -911,
        autorId: -12,
        autorNome: 'Carla Mendes',
        texto: 'Eu levo!',
        criadoEm: agora.subtract(const Duration(hours: 1, minutes: 40)),
      ),
      Comentario(
        id: -912,
        autorId: adminId,
        autorNome: 'Admin Local',
        texto: 'Fechado. Ate sexta!',
        criadoEm: agora.subtract(const Duration(hours: 1)),
      ),
    ];

    cartoes.add(
      Cartao(
        id: -951,
        idUser: adminId,
        nomeTitular: 'Admin Local',
        bandeira: 'Visa',
        ultimos4: '4242',
        validade: '12/2030',
      ),
    );

    rateios[-801] = criarRateio(
      partidaId: -801,
      valorQuadra: 180,
      taxaPercentual: 0,
    );
    rateios[-803] = criarRateio(
      partidaId: -803,
      valorQuadra: 140,
      taxaPercentual: 0,
      todosPagos: true,
      fechado: true,
    );
  }

  static PartidaMembro _membro(
    int id,
    int? usuarioId,
    String equipe,
    String nome, {
    int gols = 0,
    bool capitao = false,
  }) {
    return PartidaMembro(
      id: id,
      idUser: usuarioId,
      equipe: equipe,
      nome: nome,
      capitao: capitao,
      gols: gols,
    );
  }

  PartidaRateio criarRateio({
    required int partidaId,
    required double valorQuadra,
    required double taxaPercentual,
    bool todosPagos = false,
    bool fechado = false,
  }) {
    final partida = buscarPartida(partidaId);
    if (partida == null) throw StateError('Partida demo nao encontrada.');
    final valores = _calculadora.calcular(
      valorQuadra: valorQuadra,
      taxaPercentual: taxaPercentual,
      participantes: partida.membros.length,
    );
    final rateioId = rateios[partidaId]?.id ?? novoId();
    final anterior = rateios[partidaId];
    final cobrancas = partida.membros.map((membro) {
      final existente = anterior?.cobrancas
          .where((item) => item.partidaMembroId == membro.id)
          .firstOrNull;
      final pago = todosPagos || existente?.pago == true;
      return RateioCobranca(
        id: existente?.id ?? novoId(),
        rateioId: rateioId,
        partidaMembroId: membro.id,
        idUser: membro.idUser,
        nome: membro.nome,
        valorQuadra: valores.valorQuadraPorJogador,
        taxaServico: valores.taxaPorJogador,
        valorTotal: valores.totalPorJogador,
        status: pago ? CobrancaStatus.pago : CobrancaStatus.pendente,
        pagoEm: pago ? DateTime.now() : null,
        metodoPagamento: existente?.metodoPagamento,
        comprovanteUrl: existente?.comprovanteUrl,
      );
    }).toList();
    final rateio = PartidaRateio(
      id: rateioId,
      partidaId: partidaId,
      valorQuadra: valorQuadra,
      taxaPercentual: taxaPercentual,
      status: fechado ? RateioStatus.fechado : RateioStatus.aberto,
      cobrancas: cobrancas,
    );
    rateios[partidaId] = rateio;
    return rateio;
  }

  Partida? buscarPartida(int id) =>
      partidas.where((p) => p.id == id).firstOrNull;

  void adicionarMembro({
    required int partidaId,
    int? idUser,
    required String equipe,
    required String nome,
    String? telefone,
  }) {
    final index = partidas.indexWhere((p) => p.id == partidaId);
    if (index < 0) return;
    final atual = partidas[index];
    partidas[index] = copiarPartida(
      atual,
      membros: [
        ...atual.membros,
        PartidaMembro(
          id: novoId(),
          partidaId: partidaId,
          idUser: idUser,
          telefone: telefone,
          equipe: equipe,
          nome: nome,
          capitao: false,
        ),
      ],
    );
  }

  void removerMembro({
    required int partidaId,
    required int membroId,
  }) {
    final index = partidas.indexWhere((p) => p.id == partidaId);
    if (index < 0) return;
    final atual = partidas[index];
    partidas[index] = copiarPartida(
      atual,
      membros: atual.membros.where((membro) => membro.id != membroId).toList(),
    );
  }

  Partida copiarPartida(
    Partida partida, {
    String? status,
    int? placarTime1,
    int? placarTime2,
    List<PartidaMembro>? membros,
  }) {
    return Partida(
      id: partida.id,
      idEstabelecimento: partida.idEstabelecimento,
      idQuadra: partida.idQuadra,
      organizadorId: partida.organizadorId,
      organizadorUid: partida.organizadorUid,
      organizadorNome: partida.organizadorNome,
      duracao: partida.duracao,
      dataHora: partida.dataHora,
      status: status ?? partida.status,
      preco: partida.preco,
      visibilidade: partida.visibilidade,
      modalidade: partida.modalidade,
      formato: partida.formato,
      formacaoTime1: partida.formacaoTime1,
      formacaoTime2: partida.formacaoTime2,
      placarTime1: placarTime1 ?? partida.placarTime1,
      placarTime2: placarTime2 ?? partida.placarTime2,
      grupoRecorrencia: partida.grupoRecorrencia,
      recorrencia: partida.recorrencia,
      recorrenciaAte: partida.recorrenciaAte,
      membros: membros ?? partida.membros,
      quadraNome: partida.quadraNome,
      estabelecimentoNome: partida.estabelecimentoNome,
    );
  }

  List<Usuario> get amigos =>
      usuarios.where((u) => _amigosIds.contains(u.id)).toList();

  List<PedidoAmizade> get pedidos => usuarios
      .where(
        (usuario) =>
            _statusAmizades[usuario.id] == StatusAmizade.pendenteRecebido,
      )
      .map(
        (usuario) => PedidoAmizade(
          amizadeId: -9000 + usuario.id,
          usuarioId: usuario.id,
          nome: usuario.nomeCompleto,
          email: usuario.email,
        ),
      )
      .toList();

  List<UsuarioBusca> buscarUsuarios(String termo) {
    final busca = termo.toLowerCase();
    return usuarios
        .where((u) => u.id != adminId)
        .where((u) =>
            u.nomeCompleto.toLowerCase().contains(busca) ||
            u.email.toLowerCase().contains(busca))
        .map(
          (u) => UsuarioBusca(
            id: u.id,
            nome: u.nomeCompleto,
            email: u.email,
            status: _amigosIds.contains(u.id)
                ? StatusAmizade.amigos
                : _statusAmizades[u.id] ?? StatusAmizade.nenhuma,
            amizadeId: _statusAmizades.containsKey(u.id) ? -9000 + u.id : null,
          ),
        )
        .toList();
  }

  void enviarPedidoAmizade(int usuarioId) {
    if (_amigosIds.contains(usuarioId)) return;
    _statusAmizades[usuarioId] = StatusAmizade.pendenteEnviado;
  }

  void responderPedidoAmizade(int amizadeId, bool aceitar) {
    final usuarioId = amizadeId + 9000;
    if (aceitar) {
      _amigosIds.add(usuarioId);
    }
    _statusAmizades.remove(usuarioId);
  }

  GamificacaoUsuario get gamificacaoAdmin => GamificacaoUsuario(
        pontos: 360,
        partidasConfirmadas: 12,
        pagamentosEmDia: 9,
        pagamentosPendentes: rateios.values
            .expand((r) => r.cobrancas)
            .where((c) => c.idUser == adminId && !c.quitado)
            .length,
        confiabilidade: 97,
      );

  List<LinhaClassificacao> get classificacaoDemo => [
        LinhaClassificacao(
          clubeId: -311,
          nome: 'Joga10 FC',
          cor: '#1B3A6B',
          jogos: 2,
          vitorias: 2,
          empates: 0,
          derrotas: 0,
          golsPro: 7,
          golsContra: 3,
          saldo: 4,
          pontos: 6,
        ),
        LinhaClassificacao(
          clubeId: -313,
          nome: 'Resenha City',
          cor: '#27AE60',
          jogos: 2,
          vitorias: 1,
          empates: 0,
          derrotas: 1,
          golsPro: 4,
          golsContra: 4,
          saldo: 0,
          pontos: 3,
        ),
        LinhaClassificacao(
          clubeId: -312,
          nome: 'Vila United',
          cor: '#C0392B',
          jogos: 2,
          vitorias: 0,
          empates: 0,
          derrotas: 2,
          golsPro: 2,
          golsContra: 6,
          saldo: -4,
          pontos: 0,
        ),
      ];
}
