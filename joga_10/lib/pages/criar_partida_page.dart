import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/domain/services/recorrencia_partida.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/contatos.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class CriarPartidaPage extends StatefulWidget {
  const CriarPartidaPage({super.key});

  @override
  State<CriarPartidaPage> createState() => _CriarPartidaPageState();
}

class _CriarPartidaPageState extends State<CriarPartidaPage> {
  final _estabRepo = EstabelecimentoRepository();
  final _partidaRepo = PartidaRepository();

  List<Estabelecimentos> _estabs = [];
  Estabelecimentos? _estabSel;
  DateTime? _dataHora;
  String _duracao = '1h';
  String _visibilidade = VisibilidadePartida.publica;
  String _modalidade = ModalidadePartida.futebol;
  String _formato = '5x5';
  String _recorrencia = TipoRecorrenciaPartida.nenhuma;
  DateTime? _recorrenciaAte;
  final List<PartidaMembro> _membros = [];

  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final estabs = await _estabRepo.listarTodos();
      // adiciona o organizador ao Time 1 por padrão
      final nome = Sessao.instance.atual?.nomeCompleto ?? 'Eu';
      final id = Sessao.instance.atual?.id;
      _membros.add(PartidaMembro(idUser: id, equipe: Equipe.time1, nome: nome));
      if (mounted) {
        setState(() {
          _estabs = estabs;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _onEstabChanged(Estabelecimentos? e) {
    setState(() {
      _estabSel = e;
    });
  }

  void _alterarModalidade(String modalidade) {
    setState(() {
      _modalidade = modalidade;
      _formato = ModalidadePartida.formatoPadrao(modalidade);
    });
  }

  Future<void> _abrirMapa() async {
    final local = _estabSel;
    if (local == null) return;
    final Uri uri;
    if (local.googleMapsUrl != null && local.googleMapsUrl!.isNotEmpty) {
      uri = Uri.parse(local.googleMapsUrl!);
    } else {
      final query = local.temLocalizacao
          ? '${local.latitude},${local.longitude}'
          : '${local.nome}, ${local.enderecoResumo}';
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': query,
      });
    }
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      _msg('Não foi possível abrir o Google Maps.');
    }
  }

  Future<void> _escolherDataHora() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: agora.subtract(const Duration(days: 1)),
      lastDate: agora.add(const Duration(days: 365)),
    );
    if (data == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _dataHora =
          DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
      if (_recorrencia != TipoRecorrenciaPartida.nenhuma &&
          _recorrenciaAte == null) {
        _recorrenciaAte = _fimPadraoRecorrencia(_dataHora!, _recorrencia);
      }
    });
  }

  DateTime _fimPadraoRecorrencia(DateTime inicio, String recorrencia) {
    switch (recorrencia) {
      case TipoRecorrenciaPartida.diaria:
        return inicio.add(const Duration(days: 7));
      case TipoRecorrenciaPartida.semanal:
        return inicio.add(const Duration(days: 28));
      case TipoRecorrenciaPartida.mensal:
        return DateTime(
          inicio.year,
          inicio.month + 3,
          inicio.day,
          inicio.hour,
          inicio.minute,
        );
      default:
        return inicio;
    }
  }

  void _alterarRecorrencia(String tipo) {
    setState(() {
      _recorrencia = tipo;
      _recorrenciaAte =
          tipo == TipoRecorrenciaPartida.nenhuma || _dataHora == null
              ? null
              : _fimPadraoRecorrencia(_dataHora!, tipo);
    });
  }

  Future<void> _escolherFimRecorrencia() async {
    if (_dataHora == null) {
      _msg('Escolha primeiro a data e a hora da partida.');
      return;
    }
    final inicio = _dataHora!;
    final data = await showDatePicker(
      context: context,
      initialDate:
          _recorrenciaAte ?? _fimPadraoRecorrencia(inicio, _recorrencia),
      firstDate: DateTime(inicio.year, inicio.month, inicio.day),
      lastDate: inicio.add(const Duration(days: 365)),
    );
    if (data == null || !mounted) return;
    setState(() {
      _recorrenciaAte = DateTime(
        data.year,
        data.month,
        data.day,
        inicio.hour,
        inicio.minute,
      );
    });
  }

  int get _totalOcorrencias {
    if (_dataHora == null) return 0;
    try {
      return const RecorrenciaPartida()
          .gerarDatas(
            inicio: _dataHora!,
            tipo: _recorrencia,
            ate: _recorrenciaAte,
          )
          .length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _adicionarJogador() async {
    final resultado = await showDialog<PartidaMembro>(
      context: context,
      builder: (_) => const _DialogJogador(),
    );
    if (resultado != null) setState(() => _membros.add(resultado));
  }

  Future<void> _salvar() async {
    if (_estabSel == null) {
      _msg('Selecione o estabelecimento.');
      return;
    }
    if (_dataHora == null) {
      _msg('Escolha a data e a hora.');
      return;
    }
    if (_recorrencia != TipoRecorrenciaPartida.nenhuma &&
        _recorrenciaAte == null) {
      _msg('Escolha até quando a partida deverá se repetir.');
      return;
    }
    final id = await Sessao.instance.usuarioId;
    if (id == null) {
      _msg('Sessão expirada. Faça login novamente.');
      return;
    }
    setState(() => _salvando = true);
    try {
      await _partidaRepo.criar(
        idEstabelecimento: _estabSel!.id,
        organizadorId: id,
        duracao: _duracao,
        dataHora: _dataHora!,
        preco: 0,
        visibilidade: _visibilidade,
        modalidade: _modalidade,
        formato: _formato,
        membros: _membros,
        recorrencia: _recorrencia,
        recorrenciaAte: _recorrenciaAte,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _msg('Erro ao criar a partida.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova partida')),
      body: _carregando
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _label('Modalidade'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: ModalidadePartida.futebol,
                      icon: Icon(Icons.sports_soccer),
                      label: Text('Futebol'),
                    ),
                    ButtonSegment(
                      value: ModalidadePartida.volei,
                      icon: Icon(
                        Icons.sports_volleyball,
                        key: Key('modalidadeVolei'),
                      ),
                      label: Text('Vôlei'),
                    ),
                  ],
                  selected: {_modalidade},
                  onSelectionChanged: (selecao) =>
                      _alterarModalidade(selecao.first),
                ),
                const SizedBox(height: 20),
                _label('Visibilidade'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: VisibilidadePartida.publica,
                      icon: Icon(Icons.public),
                      label: Text('Pública'),
                    ),
                    ButtonSegment(
                      value: VisibilidadePartida.privada,
                      icon: Icon(Icons.lock_outline),
                      label: Text('Privada'),
                    ),
                  ],
                  selected: {_visibilidade},
                  onSelectionChanged: (selecao) =>
                      setState(() => _visibilidade = selecao.first),
                ),
                const SizedBox(height: 6),
                Text(
                  _visibilidade == VisibilidadePartida.publica
                      ? 'Todos os usuários poderão encontrar e entrar na partida.'
                      : 'Somente o organizador e participantes convidados terão acesso.',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                _label('Local'),
                DropdownButtonFormField<Estabelecimentos>(
                  key: const Key('estabelecimentoDropdown'),
                  initialValue: _estabSel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.stadium_outlined)),
                  hint: const Text('Selecione o estabelecimento'),
                  items: _estabs
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e.nome)))
                      .toList(),
                  onChanged: _onEstabChanged,
                ),
                if (_estabSel != null) ...[
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_estabSel!.enderecoResumo.isNotEmpty)
                          Text(
                            _estabSel!.enderecoResumo,
                            style: const TextStyle(color: AppColors.inkMuted),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _abrirMapa,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Validar local no Google Maps'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _label('Data e hora'),
                InkWell(
                  onTap: _escolherDataHora,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(prefixIcon: Icon(Icons.event)),
                    child: Text(
                      _dataHora == null
                          ? 'Escolher data e hora'
                          : formatarDataHora(_dataHora!),
                      style: TextStyle(
                        color: _dataHora == null
                            ? AppColors.inkMuted
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label('Duração'),
                DropdownButtonFormField<String>(
                  initialValue: _duracao,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.timer_outlined)),
                  items: const ['30min', '1h', '1h30', '2h']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (d) => setState(() => _duracao = d ?? '1h'),
                ),
                const SizedBox(height: 16),
                _label('Formato'),
                SegmentedButton<String>(
                  segments: _modalidade == ModalidadePartida.volei
                      ? const [
                          ButtonSegment(value: '6x6', label: Text('6x6')),
                          ButtonSegment(value: '2x2', label: Text('2x2')),
                        ]
                      : const [
                          ButtonSegment(value: '5x5', label: Text('5x5')),
                          ButtonSegment(value: '7x7', label: Text('7x7')),
                          ButtonSegment(value: '11x11', label: Text('11x11')),
                        ],
                  selected: {_formato},
                  onSelectionChanged: (selecao) =>
                      setState(() => _formato = selecao.first),
                ),
                const SizedBox(height: 16),
                _label('Repetição'),
                DropdownButtonFormField<String>(
                  initialValue: _recorrencia,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: TipoRecorrenciaPartida.valores
                      .map(
                        (tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(TipoRecorrenciaPartida.label(tipo)),
                        ),
                      )
                      .toList(),
                  onChanged: (tipo) {
                    if (tipo != null) _alterarRecorrencia(tipo);
                  },
                ),
                if (_recorrencia != TipoRecorrenciaPartida.nenhuma) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _escolherFimRecorrencia,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Repetir até',
                        prefixIcon: Icon(Icons.event_repeat_outlined),
                      ),
                      child: Text(
                        _recorrenciaAte == null
                            ? 'Escolher data final'
                            : formatarData(_recorrenciaAte!),
                      ),
                    ),
                  ),
                  if (_totalOcorrencias > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Serão criadas $_totalOcorrencias partidas com os mesmos participantes.',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Jogadores',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _adicionarJogador,
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._membros.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  final cor = m.equipe == Equipe.time1
                      ? AppColors.info
                      : AppColors.accent;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cor.withValues(alpha: 0.15),
                        child: Text(
                          m.equipe == Equipe.time1 ? '1' : '2',
                          style: TextStyle(
                              color: cor, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(m.nome),
                      subtitle: Text(
                          m.equipe == Equipe.time1 ? 'Equipe A' : 'Equipe B'),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.close, color: AppColors.inkMuted),
                        onPressed: () => setState(() => _membros.removeAt(i)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text('CRIAR PARTIDA'),
                ),
              ],
            ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.inkMuted, fontWeight: FontWeight.w700)),
      );
}

class _DialogJogador extends StatefulWidget {
  const _DialogJogador();
  @override
  State<_DialogJogador> createState() => _DialogJogadorState();
}

class _DialogJogadorState extends State<_DialogJogador> {
  final _nome = TextEditingController();
  String _equipe = Equipe.time1;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar jogador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final contato = await escolherContato();
                  if (contato == null || !context.mounted) return;
                  Navigator.pop(
                    context,
                    PartidaMembro(
                      equipe: _equipe,
                      nome: contato.nome,
                      telefone: contato.telefone,
                    ),
                  );
                },
                icon: const Icon(Icons.contacts_outlined, size: 18),
                label: const Text('Importar contato'),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: Equipe.time1, label: Text('Equipe A')),
                ButtonSegment(value: Equipe.time2, label: Text('Equipe B')),
              ],
              selected: {_equipe},
              onSelectionChanged: (s) => setState(() => _equipe = s.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_nome.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              PartidaMembro(equipe: _equipe, nome: _nome.text.trim()),
            );
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
