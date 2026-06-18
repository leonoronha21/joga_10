import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/media_storage_contract.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/Postagem.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/repositories/postagem_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_theme.dart';
import 'package:joga_10/util/format.dart';

class CriarPostPage extends StatefulWidget {
  const CriarPostPage({super.key});

  @override
  State<CriarPostPage> createState() => _CriarPostPageState();
}

class _CriarPostPageState extends State<CriarPostPage> {
  final _repo = PostagemRepository();
  final _partidaRepo = PartidaRepository();
  final _texto = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _foto;
  List<Partida> _partidas = [];
  Partida? _partida;
  String _visibilidade = VisibilidadePostagem.publico;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarPartidas();
  }

  Future<void> _carregarPartidas() async {
    final id = await Sessao.instance.usuarioId;
    if (id == null) return;
    final partidas = await _partidaRepo.listarPorUsuarioEStatus(
      id,
      PartidaStatus.finalizada,
    );
    if (mounted) {
      setState(() {
        _partidas = partidas.where((partida) => partida.publica).toList();
      });
    }
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto(ImageSource source) async {
    try {
      final img = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (img == null) return;
      final bytes = await img.readAsBytes();
      setState(() => _foto = bytes);
    } catch (_) {
      _msg('Não foi possível carregar a imagem.');
    }
  }

  void _menuFoto() {
    final midia = AppDependenciesScope.of(context).midia;
    if (!midia.uploadsHabilitados) {
      _msg(midia.mensagemIndisponivel);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _escolherFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _escolherFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publicar() async {
    if (_texto.text.trim().isEmpty && _foto == null && _partida == null) {
      _msg('Escreva algo, adicione uma foto ou vincule uma partida.');
      return;
    }
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    setState(() => _salvando = true);
    try {
      String? fotoUrl;
      final foto = _foto;
      if (foto != null) {
        final midia = AppDependenciesScope.of(context).midia;
        if (midia.uploadsHabilitados) {
          final armazenada = await midia.enviar(
            tipo: TipoMidia.postagem,
            proprietarioId: id.toString(),
            bytes: foto,
            contentType: 'image/jpeg',
          );
          fotoUrl = armazenada.url;
        }
      }
      await _repo.criar(
        autorId: id,
        texto: _texto.text.trim().isEmpty ? null : _texto.text.trim(),
        foto: _foto,
        fotoUrl: fotoUrl,
        partidaId: _partida?.id,
        visibilidade: _visibilidade,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _msg('Erro ao publicar.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova publicação')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Quem pode ver',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: VisibilidadePostagem.publico,
                icon: Icon(Icons.public),
                label: Text('Público'),
              ),
              ButtonSegment(
                value: VisibilidadePostagem.amigos,
                icon: Icon(Icons.people_outline),
                label: Text('Amigos'),
              ),
            ],
            selected: {_visibilidade},
            onSelectionChanged: (selecao) =>
                setState(() => _visibilidade = selecao.first),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<Partida>(
            initialValue: _partida,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Vincular atividade (opcional)',
              prefixIcon: Icon(Icons.emoji_events_outlined),
            ),
            hint: const Text('Selecione uma partida finalizada'),
            items: _partidas
                .map(
                  (partida) => DropdownMenuItem(
                    value: partida,
                    child: Text(
                      '${ModalidadePartida.label(partida.modalidade)} · '
                      '${formatarData(partida.dataHora)} · '
                      '${partida.placarTime1 ?? 0} x ${partida.placarTime2 ?? 0}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (partida) => setState(() => _partida = partida),
          ),
          if (_partida != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _partida = null),
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text('Remover atividade vinculada'),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _texto,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'Conte como foi o jogo ou compartilhe uma novidade...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (_foto != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: Image.memory(_foto!,
                      width: double.infinity, height: 240, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _foto = null),
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _menuFoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Adicionar foto'),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _salvando ? null : _publicar,
            child: _salvando
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4),
                  )
                : const Text('PUBLICAR'),
          ),
        ],
      ),
    );
  }
}
