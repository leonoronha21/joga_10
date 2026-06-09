import 'package:flutter/material.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/repositories/quadra_repository.dart';
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
  final _quadraRepo = QuadraRepository();
  final _partidaRepo = PartidaRepository();

  List<Estabelecimentos> _estabs = [];
  List<Quadras> _quadras = [];
  Estabelecimentos? _estabSel;
  Quadras? _quadraSel;
  DateTime? _dataHora;
  String _duracao = '1h';
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

  Future<void> _onEstabChanged(Estabelecimentos? e) async {
    setState(() {
      _estabSel = e;
      _quadraSel = null;
      _quadras = [];
    });
    if (e == null) return;
    final quadras = await _quadraRepo.listarPorEstabelecimento(e.id);
    if (mounted) setState(() => _quadras = quadras);
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
    });
  }

  Future<void> _adicionarJogador() async {
    final resultado = await showDialog<PartidaMembro>(
      context: context,
      builder: (_) => const _DialogJogador(),
    );
    if (resultado != null) setState(() => _membros.add(resultado));
  }

  Future<void> _salvar() async {
    if (_estabSel == null || _quadraSel == null) {
      _msg('Selecione o local e a quadra.');
      return;
    }
    if (_dataHora == null) {
      _msg('Escolha a data e a hora.');
      return;
    }
    final id = Sessao.instance.atual?.id;
    if (id == null) {
      _msg('Sessão expirada. Faça login novamente.');
      return;
    }
    setState(() => _salvando = true);
    try {
      await _partidaRepo.criar(
        idEstabelecimento: _estabSel!.id,
        idQuadra: _quadraSel!.id,
        organizadorId: id,
        duracao: _duracao,
        dataHora: _dataHora!,
        preco: _quadraSel!.preco,
        membros: _membros,
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
                _label('Local'),
                DropdownButtonFormField<Estabelecimentos>(
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
                const SizedBox(height: 16),
                _label('Quadra'),
                DropdownButtonFormField<Quadras>(
                  initialValue: _quadraSel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.sports_soccer)),
                  hint: Text(_estabSel == null
                      ? 'Escolha um local primeiro'
                      : 'Selecione a quadra'),
                  items: _quadras
                      .map((q) => DropdownMenuItem(
                            value: q,
                            child:
                                Text('${q.nome} • ${formatarMoeda(q.preco)}'),
                          ))
                      .toList(),
                  onChanged: (q) => setState(() => _quadraSel = q),
                ),
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
                      subtitle:
                          Text(m.equipe == Equipe.time1 ? 'Time 1' : 'Time 2'),
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
                ButtonSegment(value: Equipe.time1, label: Text('Time 1')),
                ButtonSegment(value: Equipe.time2, label: Text('Time 2')),
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
