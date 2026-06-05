import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joga_10/repositories/postagem_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_theme.dart';

class CriarPostPage extends StatefulWidget {
  const CriarPostPage({super.key});

  @override
  State<CriarPostPage> createState() => _CriarPostPageState();
}

class _CriarPostPageState extends State<CriarPostPage> {
  final _repo = PostagemRepository();
  final _texto = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _foto;
  bool _salvando = false;

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
    if (_texto.text.trim().isEmpty && _foto == null) {
      _msg('Escreva algo ou adicione uma foto.');
      return;
    }
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    setState(() => _salvando = true);
    try {
      await _repo.criar(
        autorId: id,
        texto: _texto.text.trim().isEmpty ? null : _texto.text.trim(),
        foto: _foto,
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
      appBar: AppBar(title: const Text('Novo lance')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _texto,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'O que rolou na pelada? Conta pra galera...',
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
              icon: const Icon(Icons.add_a_photo_outlined),
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
