import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_face_liveness/flutter_face_liveness.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/theme/app_colors.dart';

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

  static const _delayResultadoProvaDeVida = Duration(seconds: 5);
  static const _delayTransicaoSelfie = Duration(seconds: 2);

  Uint8List? _previa;
  bool _verificada = false;
  bool _processando = false;
  String? _ultimoErroVerificacao;

  Future<bool> _mostrarOrientacoes() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirme que é você'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A câmera fará uma prova de vida rápida para confirmar que há uma pessoa real presente.',
                  ),
                  SizedBox(height: 16),
                  _DicaProvaDeVida(
                    icon: Icons.light_mode_outlined,
                    texto: 'Fique em um local bem iluminado.',
                  ),
                  _DicaProvaDeVida(
                    icon: Icons.face_outlined,
                    texto: 'Mantenha apenas seu rosto dentro do contorno.',
                  ),
                  _DicaProvaDeVida(
                    icon: Icons.remove_red_eye_outlined,
                    texto: 'Siga os comandos para piscar e sorrir.',
                  ),
                  _DicaProvaDeVida(
                    icon: Icons.pan_tool_alt_outlined,
                    texto: 'Segure o celular firme durante a confirmação.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Começar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _verificar() async {
    final iniciar = await _mostrarOrientacoes();
    if (!iniciar || !mounted) return false;

    _ultimoErroVerificacao = null;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProvaDeVidaPage(
          delayResultado: _delayResultadoProvaDeVida,
          onFalha: (reason) => _ultimoErroVerificacao = reason,
        ),
      ),
    );
    return ok ?? false;
  }

  Future<void> _mostrarTransicaoSelfie() async {
    if (!mounted) return;
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Agora tire sua selfie'),
        content: const Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Prova de vida confirmada. Estamos abrindo a câmera para a foto do perfil.',
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(_delayTransicaoSelfie);
    if (mounted) Navigator.of(context).pop();
    await dialog;
  }

  Future<void> _capturar() async {
    setState(() => _processando = true);
    try {
      final verificada = await _verificar();
      if (!verificada) {
        final motivo = _ultimoErroVerificacao;
        _msg(
          motivo?.isNotEmpty == true
              ? motivo!
              : 'A confirmação facial não foi concluída. Tente novamente.',
        );
        return;
      }

      await _mostrarTransicaoSelfie();
      if (!mounted) return;

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
        _verificada = true;
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
      _msg('Não foi possível salvar a foto.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

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
                        image: MemoryImage(preview),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: preview == null
                  ? const Icon(
                      Icons.person,
                      size: 90,
                      color: AppColors.inkMuted,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.info),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Confirme que é você, ao vivo, seguindo dois comandos rápidos. Depois, tire sua selfie.',
                    style: TextStyle(fontSize: 12, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _processando ? null : _capturar,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              _previa == null
                  ? 'Confirmar e tirar selfie'
                  : 'Tirar outra selfie',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_previa == null || _processando) ? null : _salvar,
            child: _processando
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Text('SALVAR FOTO'),
          ),
        ],
      ),
    );
  }
}

class _ProvaDeVidaPage extends StatefulWidget {
  final Duration delayResultado;
  final ValueChanged<String> onFalha;

  const _ProvaDeVidaPage({
    required this.delayResultado,
    required this.onFalha,
  });

  @override
  State<_ProvaDeVidaPage> createState() => _ProvaDeVidaPageState();
}

class _ProvaDeVidaPageState extends State<_ProvaDeVidaPage> {
  bool? _sucesso;
  String? _mensagem;

  bool get _mostrandoResultado => _sucesso != null;

  Future<void> _finalizar({
    required bool sucesso,
    required String mensagem,
  }) async {
    if (_mostrandoResultado) return;
    setState(() {
      _sucesso = sucesso;
      _mensagem = mensagem;
    });
    await Future.delayed(widget.delayResultado);
    if (!mounted) return;
    Navigator.pop(context, sucesso);
  }

  @override
  Widget build(BuildContext context) {
    final sucesso = _sucesso;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmação facial')),
      body: Stack(
        children: [
          FlutterFaceLiveness(
            actions: const [
              LivenessAction.blink,
              LivenessAction.smile,
            ],
            config: const LivenessConfig(
              randomizeActions: true,
              enableAntiSpoof: true,
              enableVideoReplayDetection: true,
            ),
            onSuccess: (result) {
              _finalizar(
                sucesso: result.isSuccess,
                mensagem: result.isSuccess
                    ? 'Prova de vida confirmada. Aguarde um momento para seguir para a selfie.'
                    : 'Não foi possível confirmar a prova de vida.',
              );
            },
            onFailed: (reason) {
              widget.onFalha(reason);
              _finalizar(
                sucesso: false,
                mensagem: reason.isNotEmpty
                    ? reason
                    : 'Não foi possível concluir a prova de vida.',
              );
            },
          ),
          if (sucesso != null)
            _ResultadoProvaDeVida(
              sucesso: sucesso,
              mensagem: _mensagem ?? '',
              segundos: widget.delayResultado.inSeconds,
            ),
        ],
      ),
    );
  }
}

class _ResultadoProvaDeVida extends StatelessWidget {
  final bool sucesso;
  final String mensagem;
  final int segundos;

  const _ResultadoProvaDeVida({
    required this.sucesso,
    required this.mensagem,
    required this.segundos,
  });

  @override
  Widget build(BuildContext context) {
    final cor = sucesso ? AppColors.success : AppColors.danger;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sucesso
                    ? Icons.verified_user_outlined
                    : Icons.error_outline_rounded,
                color: cor,
                size: 54,
              ),
              const SizedBox(height: 14),
              Text(
                sucesso ? 'Identidade confirmada' : 'Confirmação não concluída',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              Text(
                'Aguarde $segundos segundos...',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DicaProvaDeVida extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _DicaProvaDeVida({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
