import 'package:flutter/material.dart';

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
      if (mounted) {
        setState(() {
          _posts = posts;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = true;
          _carregando = false;
        });
      }
    }
  }

  Future<void> _alternarCurtida(int index) async {
    final id = await Sessao.instance.usuarioId;
    if (id == null) return;
    final post = _posts[index];
    final novo = post.copyWith(
      curtiuEu: !post.curtiuEu,
      curtidas: post.curtidas + (post.curtiuEu ? -1 : 1),
    );
    setState(() => _posts[index] = novo);
    try {
      await _repo.definirCurtida(post.id, id, novo.curtiuEu);
    } catch (_) {
      setState(() => _posts[index] = post); // reverte
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
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Novo lance'),
      ),
      body: Column(
        children: [
          GradientHeader(
            titulo: 'Social',
            subtitulo: 'Lances e novidades da galera',
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
    if (_posts.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        EmptyState(
          icone: Icons.dynamic_feed_outlined,
          titulo:
              _descobrir ? 'Nada para descobrir ainda' : 'Seu feed está vazio',
          mensagem: _descobrir
              ? 'Ainda não há lances públicos para descobrir.'
              : 'Compartilhe um lance ou adicione amigos para ver as novidades.',
          acao: ElevatedButton(
            onPressed: _abrirCriar,
            child: const Text('Compartilhar lance'),
          ),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _PostCard(
        post: _posts[i],
        onCurtir: () => _alternarCurtida(i),
        onComentar: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PostDetalhePage(postagem: _posts[i])),
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
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.autorNome,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(tempoAtras(post.criadoEm),
                          style: const TextStyle(
                              color: AppColors.inkMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            ClipRRect(
              child: Image.memory(
                post.foto!,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onCurtir,
                  icon: Icon(
                    post.curtiuEu ? Icons.favorite : Icons.favorite_border,
                    color:
                        post.curtiuEu ? AppColors.danger : AppColors.inkMuted,
                    size: 20,
                  ),
                  label: Text('${post.curtidas}',
                      style: const TextStyle(color: AppColors.inkMuted)),
                ),
                TextButton.icon(
                  onPressed: onComentar,
                  icon: const Icon(Icons.mode_comment_outlined,
                      color: AppColors.inkMuted, size: 20),
                  label: Text('${post.comentarios}',
                      style: const TextStyle(color: AppColors.inkMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
