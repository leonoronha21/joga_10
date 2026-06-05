import 'package:flutter/material.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/pages/criar_partida_page.dart';
import 'package:joga_10/pages/partida_detalhe_page.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class PartidasPage extends StatefulWidget {
  const PartidasPage({super.key});

  @override
  State<PartidasPage> createState() => _PartidasPageState();
}

class _PartidasPageState extends State<PartidasPage> {
  final _repo = PartidaRepository();
  String _filtro = 'abertas'; // abertas | historico | todas
  late Future<List<Partida>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Partida>> _carregar() async {
    final id = await Sessao.instance.usuarioId;
    if (id == null) return [];
    return _repo.listarPorUsuario(id);
  }

  List<Partida> _filtrar(List<Partida> todas) {
    switch (_filtro) {
      case 'abertas':
        return todas
            .where((p) =>
                p.status == PartidaStatus.agendada ||
                p.status == PartidaStatus.emAndamento)
            .toList();
      case 'historico':
        return todas
            .where((p) =>
                p.status == PartidaStatus.finalizada ||
                p.status == PartidaStatus.cancelada)
            .toList();
      default:
        return todas;
    }
  }

  void _recarregar() => setState(() {
        _futuro = _carregar();
      });

  Future<void> _abrirCriar() async {
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CriarPartidaPage()),
    );
    if (criou == true) _recarregar();
  }

  String get _msgVazio {
    switch (_filtro) {
      case 'abertas':
        return 'Nenhuma partida aberta. Toque em "Nova partida" para marcar um jogo.';
      case 'historico':
        return 'Nenhuma partida no histórico ainda.';
      default:
        return 'Toque em "Nova partida" para marcar seu primeiro jogo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCriar,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova partida'),
      ),
      body: Column(
        children: [
          GradientHeader(
            titulo: 'Partidas',
            subtitulo: 'Organize e acompanhe seus jogos',
            trailing: Image.asset(
              'lib/assets/img/Joga_transparente.png',
              height: 44,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _filtroBtn('Abertas', 'abertas'),
                const SizedBox(width: 8),
                _filtroBtn('Histórico', 'historico'),
                const SizedBox(width: 8),
                _filtroBtn('Todas', 'todas'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _recarregar(),
              child: FutureBuilder<List<Partida>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const LoadingView();
                  }
                  if (snap.hasError) {
                    return _erro();
                  }
                  final partidas = _filtrar(snap.data ?? []);
                  if (partidas.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        EmptyState(
                          icone: Icons.sports_soccer,
                          titulo: 'Nenhuma partida',
                          mensagem: _msgVazio,
                          acao: _filtro == 'historico'
                              ? null
                              : ElevatedButton(
                                  onPressed: _abrirCriar,
                                  child: const Text('Criar partida'),
                                ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: partidas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _PartidaCard(
                      partida: partidas[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PartidaDetalhePage(partidaId: partidas[i].id),
                          ),
                        );
                        _recarregar();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _erro() => ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icone: Icons.cloud_off,
            titulo: 'Erro ao carregar',
            mensagem: 'Não foi possível conectar ao banco de dados.',
          ),
        ],
      );

  Widget _filtroBtn(String label, String value) {
    final ativo = _filtro == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtro = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: ativo ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ativo ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartidaCard extends StatelessWidget {
  final Partida partida;
  final VoidCallback onTap;
  const _PartidaCard({required this.partida, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.sports_soccer, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partida.quadraNome ?? 'Partida #${partida.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (partida.estabelecimentoNome != null)
                      Text(
                        partida.estabelecimentoNome!,
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 13),
                      ),
                  ],
                ),
              ),
              StatusBadge(partida.status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event, size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 6),
              Text(formatarDataHora(partida.dataHora),
                  style: const TextStyle(color: AppColors.inkMuted)),
              const Spacer(),
              if (partida.temPlacar)
                Text(
                  '${partida.placarTime1} x ${partida.placarTime2}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                )
              else ...[
                const Icon(Icons.group, size: 18, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text('${partida.membros.length}',
                    style: const TextStyle(color: AppColors.inkMuted)),
              ],
            ],
          ),
          if (partida.preco > 0) ...[
            const SizedBox(height: 6),
            Text(
              formatarMoeda(partida.preco),
              style: const TextStyle(
                  color: AppColors.primaryDark, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
