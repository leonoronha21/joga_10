import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_face_liveness/flutter_face_liveness.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/theme/app_colors.dart';

/// Fluxo de foto de perfil com verificação facial (liveness).
///
/// O liveness (package flutter_face_liveness) exige Flutter 3.35+/Dart 3.9.
/// Enquanto o gate não está ativo, a captura segue sem verificação
/// (foto_verificada = false). Quando o liveness estiver ligado, [_verificar]
/// roda o desafio facial e, em caso de sucesso, marca a foto como verificada.
class FotoPerfilPage extends StatefulWidget {
  final int usuarioId;
  final Uint8List? fotoAtual;
  const FotoPerfilPage({super.key, required this.usuarioId, this.fotoAtual});

  @override
  State<FotoPerfilPage> createState() => _FotoPerfilPageState();
}

class _FotoPerfilPageState extends State<FotoPerfilPage> {
  final _repo = UsuarioRepository();
  final _picker = ImagePicker();
  Uint8List? _previa;
  bool _verificada = false;
  bool _processando = false;

  bool get _livenessDisponivel => true;

  /// Roda o desafio de prova de vida (flutter_face_liveness) numa tela cheia.
  /// Retorna true se o usuário passou na verificação.
  Future<bool> _verificar() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Verificação facial')),
          body: FlutterFaceLiveness(
            actions: const [
              LivenessAction.blink,
              LivenessAction.smile,
            ],
            config: const LivenessConfig(
              randomizeActions: true,
              enableAntiSpoof: true,
              enableVideoReplayDetection: true,
            ),
            onSuccess: (result) =>
                Navigator.pop(context, result.isSuccess),
            onFailed: (reason) => Navigator.pop(context, false),
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  Future<void> _capturar() async {
    setState(() => _processando = true);
    try {
      bool verificada = false;
      if (_livenessDisponivel) {
        verificada = await _verificar();
        if (!verificada) {
          _msg('Verificação facial não concluída.');
          return;
        }
      }
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 512,
        imageQuality: 60,
      );
      if (img == null) return;
      final bytes = await img.readAsBytes();
      if (!mounted) return;
      setState(() {
        _previa = bytes;
        _verificada = verificada;
      });
    } catch (_) {
      _msg('Não foi possível capturar a foto.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _salvar() async {
    final foto = _previa;
    if (foto == null) return;
    setState(() => _processando = true);
    try {
      await _repo.salvarFoto(widget.usuarioId, foto, verificada: _verificada);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _msg('Erro ao salvar a foto.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final preview = _previa ?? widget.fotoAtual;
    return Scaffold(
      appBar: AppBar(title: const Text('Foto de perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.border, width: 2),
                image: preview != null
                    ? DecorationImage(
                        image: MemoryImage(preview), fit: BoxFit.cover)
                    : null,
              ),
              child: preview == null
                  ? const Icon(Icons.person,
                      size: 90, color: AppColors.inkMuted)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _livenessDisponivel ? Icons.verified_user : Icons.face,
                  color: AppColors.info,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _livenessDisponivel
                        ? 'Faça a verificação facial (prova de vida) e tire sua selfie.'
                        : 'A foto é capturada pela câmera frontal. A verificação '
                            'facial (liveness) será ativada após atualizar o Flutter.',
                    style: const TextStyle(fontSize: 12, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _processando ? null : _capturar,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(_previa == null ? 'Tirar foto' : 'Tirar outra'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_previa == null || _processando) ? null : _salvar,
            child: _processando
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4))
                : const Text('SALVAR FOTO'),
          ),
        ],
      ),
    );
  }
}
