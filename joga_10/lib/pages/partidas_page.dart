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
  String _filtro = 'minhas';
  late Future<List<Partida>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Partida>> _carregar() async {
    final id = await Sessao.instance.usuarioId;
    if (id == null) return const [];
    switch (_filtro) {
      case 'publicas':
        return _repo.listarPublicas();
      case 'historico':
        return (await _repo.listarPorUsuario(id))
            .where((partida) =>
                partida.status == PartidaStatus.finalizada ||
                partida.status == PartidaStatus.cancelada)
            .toList();
      default:
        return (await _repo.listarPorUsuario(id))
            .where((partida) =>
                partida.status == PartidaStatus.agendada ||
                partida.status == PartidaStatus.emAndamento)
            .toList();
    }
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  void _selecionarFiltro(String filtro) {
    if (_filtro == filtro) return;
    setState(() {
      _filtro = filtro;
      _futuro = _carregar();
    });
  }

  Future<void> _abrirCriar() async {
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CriarPartidaPage()),
    );
    if (criou == true) _recarregar();
  }

  String get _msgVazio {
    switch (_filtro) {
      case 'minhas':
        return 'Você ainda não participa de nenhuma partida aberta.';
      case 'publicas':
        return 'Nenhuma partida pública disponível no momento.';
      case 'historico':
        return 'Nenhuma partida no histórico ainda.';
      default:
        return 'Crie sua primeira partida.';
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
            subtitulo: 'Organize seus jogos ou encontre partidas públicas',
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
                _filtroBtn('Minhas', 'minhas'),
                const SizedBox(width: 8),
                _filtroBtn('Públicas', 'publicas'),
                const SizedBox(width: 8),
                _filtroBtn('Histórico', 'historico'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _recarregar(),
              child: FutureBuilder<List<Partida>>(
                future: _futuro,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LoadingView();
                  }
                  if (snapshot.hasError) return _erro();
                  final partidas = snapshot.data ?? [];
                  if (partidas.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        EmptyState(
                          icone: _filtro == 'publicas'
                              ? Icons.public
                              : Icons.sports,
                          titulo: 'Nenhuma partida',
                          mensagem: _msgVazio,
                          acao: _filtro == 'minhas'
                              ? ElevatedButton(
                                  onPressed: _abrirCriar,
                                  child: const Text('Criar partida'),
                                )
                              : null,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: partidas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _PartidaCard(
                      partida: partidas[index],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartidaDetalhePage(
                              partidaId: partidas[index].id,
                            ),
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
            mensagem: 'Não foi possível carregar as partidas.',
          ),
        ],
      );

  Widget _filtroBtn(String label, String value) {
    final ativo = _filtro == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selecionarFiltro(value),
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
    final icone =
        partida.isVolei ? Icons.sports_volleyball : Icons.sports_soccer;
    final cor = partida.isVolei ? const Color(0xFF2563EB) : AppColors.primary;
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
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partida.estabelecimentoNome ??
                          partida.quadraNome ??
                          'Partida #${partida.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${ModalidadePartida.label(partida.modalidade)} · ${partida.formato}',
                      style: TextStyle(
                        color: cor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(partida.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                partida.publica ? Icons.public : Icons.lock_outline,
                size: 16,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 5),
              Text(
                VisibilidadePartida.label(partida.visibilidade),
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event, size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 6),
              Text(
                formatarDataHora(partida.dataHora),
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const Spacer(),
              if (partida.temPlacar)
                Text(
                  '${partida.placarTime1} x ${partida.placarTime2}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                )
              else ...[
                const Icon(Icons.group, size: 18, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  '${partida.membros.length}',
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
