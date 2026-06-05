import 'package:flutter/material.dart';

import 'package:joga_10/model/Comentario.dart';
import 'package:joga_10/model/Postagem.dart';
import 'package:joga_10/repositories/comentario_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class PostDetalhePage extends StatefulWidget {
  final Postagem postagem;
  const PostDetalhePage({super.key, required this.postagem});

  @override
  State<PostDetalhePage> createState() => _PostDetalhePageState();
}

class _PostDetalhePageState extends State<PostDetalhePage> {
  final _repo = ComentarioRepository();
  final _comentario = TextEditingController();
  late Future<List<Comentario>> _futuro;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarPorPostagem(widget.postagem.id);
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _comentario.text.trim();
    if (texto.isEmpty) return;
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    setState(() => _enviando = true);
    try {
      await _repo.adicionar(widget.postagem.id, id, texto);
      _comentario.clear();
      setState(() {
        _futuro = _repo.listarPorPostagem(widget.postagem.id);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao comentar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.postagem;
    return Scaffold(
      appBar: AppBar(title: const Text('Lance')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                p.autorNome.isNotEmpty
                                    ? p.autorNome[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.autorNome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(tempoAtras(p.criadoEm),
                                    style: const TextStyle(
                                        color: AppColors.inkMuted,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (p.texto != null && p.texto!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(p.texto!,
                              style: const TextStyle(fontSize: 15)),
                        ),
                      if (p.foto != null)
                        Image.memory(p.foto!,
                            width: double.infinity,
                            height: 260,
                            fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 4),
                            Text('${p.curtidas}',
                                style: const TextStyle(
                                    color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Comentários',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                FutureBuilder<List<Comentario>>(
                  future: _futuro,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: LoadingView(),
                      );
                    }
                    final comentarios = snap.data ?? [];
                    if (comentarios.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Seja o primeiro a comentar.',
                            style: TextStyle(color: AppColors.inkMuted)),
                      );
                    }
                    return Column(
                      children: comentarios.map(_comentarioTile).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comentario,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário...',
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando ? null : _enviar,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comentarioTile(Comentario c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.inkMuted.withValues(alpha: 0.15),
            child: Text(
              c.autorNome.isNotEmpty ? c.autorNome[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.autorNome,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(tempoAtras(c.criadoEm),
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(c.texto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
