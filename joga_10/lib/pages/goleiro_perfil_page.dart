import 'package:flutter/material.dart';

import 'package:joga_10/model/Contratacao.dart';
import 'package:joga_10/repositories/goleiro_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class GoleiroPerfilPage extends StatefulWidget {
  const GoleiroPerfilPage({super.key});

  @override
  State<GoleiroPerfilPage> createState() => _GoleiroPerfilPageState();
}

class _GoleiroPerfilPageState extends State<GoleiroPerfilPage> {
  final _repo = GoleiroRepository();
  final _cidade = TextEditingController();
  final _preco = TextEditingController();
  final _obs = TextEditingController();

  bool _disponivel = true;
  int _nivel = 3;
  bool _carregando = true;
  bool _salvando = false;
  List<Contratacao> _solicitacoes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _cidade.dispose();
    _preco.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    try {
      final perfil = await _repo.meuPerfil(id);
      final solicitacoes = await _repo.contratacoesRecebidas(id);
      if (!mounted) return;
      setState(() {
        if (perfil != null) {
          _cidade.text = perfil.cidade ?? '';
          _preco.text = perfil.precoJogo.toStringAsFixed(0);
          _obs.text = perfil.observacao ?? '';
          _disponivel = perfil.disponivel;
          _nivel = perfil.nivel;
        } else {
          _cidade.text = Sessao.instance.atual?.cidade ?? '';
        }
        _solicitacoes = solicitacoes;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    setState(() => _salvando = true);
    try {
      await _repo.salvarPerfil(
        usuarioId: id,
        cidade: _cidade.text,
        preco: double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0,
        nivel: _nivel,
        disponivel: _disponivel,
        observacao: _obs.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil de goleiro salvo!')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _responder(int id, bool aceitar) async {
    await _repo.responder(id, aceitar);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sou goleiro')),
      body: _carregando
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _disponivel,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Disponível para contratação',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onChanged: (v) => setState(() => _disponivel = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cidade,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _preco,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Preço por jogo (R\$)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nível',
                    style: TextStyle(
                        color: AppColors.inkMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      onPressed: () => setState(() => _nivel = i + 1),
                      icon: Icon(
                        i < _nivel ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _obs,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    hintText: 'Ex.: pego pênalti, disponível fins de semana...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4))
                      : const Text('SALVAR PERFIL'),
                ),
                const SizedBox(height: 28),
                const Text('Solicitações recebidas',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                if (_solicitacoes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nenhuma solicitação por enquanto.',
                        style: TextStyle(color: AppColors.inkMuted)),
                  )
                else
                  ..._solicitacoes.map(_solicitacaoTile),
              ],
            ),
    );
  }

  Widget _solicitacaoTile(Contratacao c) {
    final pendente = c.status == ContratacaoStatus.pendente;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.solicitanteNome,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                StatusBadgeGenerico(
                  texto: ContratacaoStatus.label(c.status),
                  cor: c.status == ContratacaoStatus.aceita
                      ? AppColors.success
                      : c.status == ContratacaoStatus.recusada
                          ? AppColors.danger
                          : AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (c.partidaQuadra != null)
              Text(
                '${c.partidaQuadra} · ${c.partidaData != null ? formatarDataHora(c.partidaData!) : ''}',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
              )
            else
              const Text('Sem partida específica',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
            if (c.valor != null)
              Text(formatarMoeda(c.valor!),
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700)),
            if (pendente) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _responder(c.id, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _responder(c.id, true),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44)),
                      child: const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
