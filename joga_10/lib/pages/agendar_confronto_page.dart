import 'package:flutter/material.dart';

import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class AgendarConfrontoPage extends StatefulWidget {
  const AgendarConfrontoPage({super.key});

  @override
  State<AgendarConfrontoPage> createState() => _AgendarConfrontoPageState();
}

class _AgendarConfrontoPageState extends State<AgendarConfrontoPage> {
  final _repo = CampeonatoRepository();
  final _local = TextEditingController();

  List<Clube> _clubes = [];
  Clube? _casa;
  Clube? _visitante;
  DateTime? _dataHora;
  String _tipo = 'AMISTOSO';
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _local.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final clubes = await _repo.listarClubes();
      if (mounted) {
        setState(() {
          _clubes = clubes;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
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
        context: context, initialTime: const TimeOfDay(hour: 19, minute: 0));
    if (hora == null || !mounted) return;
    setState(() => _dataHora =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute));
  }

  Future<void> _salvar() async {
    if (_casa == null || _visitante == null) {
      _msg('Selecione os dois times.');
      return;
    }
    if (_casa!.id == _visitante!.id) {
      _msg('Os times devem ser diferentes.');
      return;
    }
    if (_dataHora == null) {
      _msg('Escolha data e hora.');
      return;
    }
    setState(() => _salvando = true);
    try {
      await _repo.criarConfronto(
        clubeCasaId: _casa!.id,
        clubeVisitanteId: _visitante!.id,
        dataHora: _dataHora!,
        tipo: _tipo,
        local: _local.text.trim().isEmpty ? null : _local.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _msg('Erro ao agendar.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar jogo')),
      body: _carregando
          ? const LoadingView()
          : _clubes.length < 2
              ? const EmptyState(
                  icone: Icons.groups_outlined,
                  titulo: 'Poucos times',
                  mensagem: 'Cadastre pelo menos 2 times para agendar um jogo.',
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _label('Mandante'),
                    _dropdownClube(_casa, (c) => setState(() => _casa = c)),
                    const SizedBox(height: 16),
                    _label('Visitante'),
                    _dropdownClube(
                        _visitante, (c) => setState(() => _visitante = c)),
                    const SizedBox(height: 16),
                    _label('Tipo'),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'AMISTOSO', label: Text('Amistoso')),
                        ButtonSegment(value: 'OFICIAL', label: Text('Oficial')),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: (s) => setState(() => _tipo = s.first),
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
                                  : AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Local'),
                    TextField(
                      controller: _local,
                      decoration: const InputDecoration(
                        hintText: 'Ex.: Arena Bola na Rede',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.4))
                          : const Text('AGENDAR'),
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

  Widget _dropdownClube(Clube? value, ValueChanged<Clube?> onChanged) {
    return DropdownButtonFormField<Clube>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.shield_outlined)),
      hint: const Text('Selecione o time'),
      items: _clubes
          .map((c) => DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: c.corValue),
                    const SizedBox(width: 8),
                    Text(c.nome),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
