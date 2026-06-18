import 'package:flutter/material.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/Postagem.dart';
import 'package:joga_10/pages/amigos_page.dart';
import 'package:joga_10/pages/criar_post_page.dart';
import 'package:joga_10/pages/post_detalhe_page.dart';
import 'package:joga_10/repositories/postagem_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _repo = PostagemRepository();
  List<Postagem> _posts = [];
  bool _carregando = true;
  bool _erro = false;
  bool _descobrir = false;
  String _tipoFiltro = 'TODOS';

  List<Postagem> get _postsFiltrados {
    if (_tipoFiltro == 'ATIVIDADES') {
      return _posts.where((post) => post.isAtividade).toList();
    }
    if (_tipoFiltro == 'PUBLICACOES') {
      return _posts.where((post) => !post.isAtividade).toList();
    }
    return _posts;
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final id = await Sessao.instance.usuarioId;
      final posts = id == null
          ? <Postagem>[]
          : _descobrir
              ? await _repo.listarDescobrir(id)
              : await _repo.listarFeed(id);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = true;
        _carregando = false;
      });
    }
  }

  Future<void> _alternarCurtida(Postagem post) async {
    final id = await Sessao.instance.usuarioId;
    if (id == null) return;
    final index = _posts.indexWhere((item) => item.id == post.id);
    if (index < 0) return;
    final novo = post.copyWith(
      curtiuEu: !post.curtiuEu,
      curtidas: post.curtidas + (post.curtiuEu ? -1 : 1),
    );
    setState(() => _posts[index] = novo);
    try {
      await _repo.definirCurtida(post.id, id, novo.curtiuEu);
    } catch (_) {
      if (mounted) setState(() => _posts[index] = post);
    }
  }

  Future<void> _abrirCriar() async {
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CriarPostPage()),
    );
    if (criou == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCriar,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: Column(
        children: [
          GradientHeader(
            titulo: 'Social',
            subtitulo: 'Atividades, aplausos e histórias da galera',
            trailing: IconButton.filledTonal(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AmigosPage()),
              ).then((_) => _carregar()),
              icon: const Icon(Icons.group_outlined, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
              tooltip: 'Amigos',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.people_outline),
                  label: Text('Amigos'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.explore_outlined),
                  label: Text('Descobrir'),
                ),
              ],
              selected: {_descobrir},
              onSelectionChanged: (selecao) {
                final descobrir = selecao.first;
                if (descobrir == _descobrir) return;
                setState(() => _descobrir = descobrir);
                _carregar();
              },
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _filtroTipo('Todos', 'TODOS', Icons.dynamic_feed_outlined),
                const SizedBox(width: 8),
                _filtroTipo(
                  'Atividades',
                  'ATIVIDADES',
                  Icons.emoji_events_outlined,
                ),
                const SizedBox(width: 8),
                _filtroTipo(
                  'Publicações',
                  'PUBLICACOES',
                  Icons.chat_bubble_outline,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _carregar,
              child: _build(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtroTipo(String label, String value, IconData icon) {
    return ChoiceChip(
      selected: _tipoFiltro == value,
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onSelected: (_) => setState(() => _tipoFiltro = value),
    );
  }

  Widget _build() {
    if (_carregando) return const LoadingView();
    if (_erro) {
      return ListView(children: const [
        SizedBox(height: 80),
        EmptyState(
          icone: Icons.cloud_off,
          titulo: 'Erro ao carregar o feed',
          mensagem: 'Não foi possível conectar ao banco.',
        ),
      ]);
    }

    final posts = _postsFiltrados;
    if (posts.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        EmptyState(
          icone: _tipoFiltro == 'ATIVIDADES'
              ? Icons.emoji_events_outlined
              : Icons.dynamic_feed_outlined,
          titulo: _tipoFiltro == 'ATIVIDADES'
              ? 'Nenhuma atividade por aqui'
              : _descobrir
                  ? 'Nada para descobrir ainda'
                  : 'Seu feed está vazio',
          mensagem: _descobrir
              ? 'Ainda não há publicações públicas para descobrir.'
              : 'Compartilhe uma atividade ou adicione amigos para ver novidades.',
          acao: ElevatedButton(
            onPressed: _abrirCriar,
            child: const Text('Criar publicação'),
          ),
        ),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) => _PostCard(
        post: posts[index],
        onCurtir: () => _alternarCurtida(posts[index]),
        onComentar: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetalhePage(postagem: posts[index]),
            ),
          );
          _carregar();
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Postagem post;
  final VoidCallback onCurtir;
  final VoidCallback onComentar;

  const _PostCard({
    required this.post,
    required this.onCurtir,
    required this.onComentar,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    post.autorNome.isNotEmpty
                        ? post.autorNome[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.autorNome,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        tempoAtras(post.criadoEm),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  post.publica ? Icons.public : Icons.people_outline,
                  size: 17,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
          if (post.isAtividade) AtividadeResumo(post: post),
          if (post.texto != null && post.texto!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(post.texto!, style: const TextStyle(fontSize: 15)),
            ),
          if (post.fotoUrl != null)
            Image.network(
              post.fotoUrl!,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            )
          else if (post.foto != null)
            Image.memory(
              post.foto!,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onCurtir,
                  icon: Icon(
                    post.curtiuEu
                        ? Icons.thumb_up_alt
                        : Icons.thumb_up_alt_outlined,
                    color:
                        post.curtiuEu ? AppColors.primary : AppColors.inkMuted,
                    size: 20,
                  ),
                  label: Text(
                    '${post.curtidas} aplausos',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
                TextButton.icon(
                  onPressed: onComentar,
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    color: AppColors.inkMuted,
                    size: 20,
                  ),
                  label: Text(
                    '${post.comentarios}',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AtividadeResumo extends StatelessWidget {
  final Postagem post;

  const AtividadeResumo({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final volei = post.atividadeModalidade == ModalidadePartida.volei;
    final cor = volei ? const Color(0xFF2563EB) : AppColors.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                volei ? Icons.sports_volleyball : Icons.sports_soccer,
                color: cor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${post.modalidadeLabel} concluído',
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (post.atividadePlacarEquipeA != null &&
                  post.atividadePlacarEquipeB != null)
                Text(
                  '${post.atividadePlacarEquipeA} x ${post.atividadePlacarEquipeB}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
            ],
          ),
          if (post.atividadeLocal != null) ...[
            const SizedBox(height: 8),
            Text(
              post.atividadeLocal!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          if (post.atividadeDataHora != null) ...[
            const SizedBox(height: 2),
            Text(
              formatarDataHora(post.atividadeDataHora!),
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              if (post.atividadeParticipantes != null)
                _metrica(
                  Icons.group_outlined,
                  '${post.atividadeParticipantes} participantes',
                ),
              if (post.atividadeDuracao != null)
                _metrica(Icons.timer_outlined, post.atividadeDuracao!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metrica(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
        ),
      ],
    );
  }
}
