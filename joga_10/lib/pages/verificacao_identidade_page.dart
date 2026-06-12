import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_face_liveness/flutter_face_liveness.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joga_10/domain/contracts/media_storage_contract.dart';
import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/services/biometria_facial.dart';
import 'package:joga_10/theme/app_colors.dart';

enum _Etapa { documento, provaVida, selfie, validando, resultado }

/// Fluxo de verificação de identidade:
/// 1) Foto do documento (CNH/RG) → 2) Prova de vida (liveness) →
/// 3) Selfie → 4) Face match (biometria) documento × selfie.
///
/// O documento é processado **somente no dispositivo** (não é enviado/armazenado).
/// Em caso de match, a selfie vira a foto de perfil verificada.
class VerificacaoIdentidadePage extends StatefulWidget {
  final int usuarioId;
  final MediaStorageContract midia;

  const VerificacaoIdentidadePage({
    super.key,
    required this.usuarioId,
    required this.midia,
  });

  @override
  State<VerificacaoIdentidadePage> createState() =>
      _VerificacaoIdentidadePageState();
}

class _VerificacaoIdentidadePageState extends State<VerificacaoIdentidadePage> {
  final _repo = UsuarioRepository();
  final _picker = ImagePicker();
  final _biometria = BiometriaFacial();

  _Etapa _etapa = _Etapa.documento;
  String? _docPath;
  String? _selfiePath;
  bool _ocupado = false;
  ResultadoBiometria? _resultado;

  @override
  void dispose() {
    _biometria.dispose();
    super.dispose();
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  // ── 1. Documento ──────────────────────────────────────────────────────────
  Future<void> _tirarDocumento() async {
    setState(() => _ocupado = true);
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1280,
        imageQuality: 75,
      );
      if (img == null) return;
      final temRosto = await _biometria.temRosto(img.path);
      if (!temRosto) {
        _msg('Não encontramos um rosto no documento. Tente novamente.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _docPath = img.path;
        _etapa = _Etapa.provaVida;
      });
    } catch (_) {
      _msg('Não foi possível capturar o documento.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ── 2. Prova de vida ────────────────────────────────────────────────────────
  Future<void> _provaDeVida() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _ProvaDeVidaPage()),
    );
    if (ok == true && mounted) {
      setState(() => _etapa = _Etapa.selfie);
    } else {
      _msg('Prova de vida não concluída. Tente novamente.');
    }
  }

  // ── 3. Selfie + 4. Match ─────────────────────────────────────────────────────
  Future<void> _tirarSelfieEValidar() async {
    setState(() => _ocupado = true);
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (img == null) return;
      _selfiePath = img.path;
      if (!mounted) return;
      setState(() => _etapa = _Etapa.validando);

      final resultado = await _biometria.comparar(
        caminhoDocumento: _docPath!,
        caminhoSelfie: _selfiePath!,
      );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _etapa = _Etapa.resultado;
      });
    } catch (_) {
      _msg('Não foi possível validar a selfie.');
      if (mounted) setState(() => _etapa = _Etapa.selfie);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ── Persistência ────────────────────────────────────────────────────────────
  Future<void> _salvar({required bool verificada}) async {
    final selfie = _selfiePath;
    if (selfie == null) return;
    setState(() => _ocupado = true);
    try {
      final bytes = await File(selfie).readAsBytes();
      final armazenada = await widget.midia.enviar(
        tipo: TipoMidia.fotoPerfil,
        proprietarioId: widget.usuarioId.toString(),
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      await _repo.salvarFotoUrl(
        widget.usuarioId,
        armazenada.url,
        verificada: verificada,
        score: _resultado?.similaridade,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _msg('Não foi possível salvar a foto.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _recomecar() {
    setState(() {
      _etapa = _Etapa.documento;
      _docPath = null;
      _selfiePath = null;
      _resultado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação de identidade')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _conteudo(),
        ),
      ),
    );
  }

  Widget _conteudo() {
    switch (_etapa) {
      case _Etapa.documento:
        return _passo(
          numero: 1,
          icone: Icons.badge_outlined,
          titulo: 'Foto do documento',
          texto:
              'Tire uma foto nítida da frente da sua CNH ou RG, com o rosto visível e boa iluminação.',
          acao: 'Tirar foto do documento',
          onAcao: _tirarDocumento,
        );
      case _Etapa.provaVida:
        return _passo(
          numero: 2,
          icone: Icons.verified_user_outlined,
          titulo: 'Prova de vida',
          texto:
              'Agora vamos confirmar que é você ao vivo. Siga os comandos (piscar e sorrir) com o rosto dentro do contorno.',
          acao: 'Iniciar prova de vida',
          onAcao: _provaDeVida,
        );
      case _Etapa.selfie:
        return _passo(
          numero: 3,
          icone: Icons.face_outlined,
          titulo: 'Selfie',
          texto:
              'Por fim, tire uma selfie. Vamos comparar o seu rosto com o do documento (biometria).',
          acao: 'Tirar selfie e validar',
          onAcao: _tirarSelfieEValidar,
        );
      case _Etapa.validando:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text('Validando identidade...',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text(
                'Comparando o rosto do documento com a selfie. Pode levar alguns segundos na primeira vez (baixando o modelo).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
            ],
          ),
        );
      case _Etapa.resultado:
        return _telaResultado();
    }
  }

  Widget _passo({
    required int numero,
    required IconData icone,
    required String titulo,
    required String texto,
    required String acao,
    required VoidCallback onAcao,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Passo $numero de 3',
            style: const TextStyle(
                color: AppColors.inkMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: Icon(icone, size: 48, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 24),
        Text(titulo,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(texto,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 15)),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _ocupado ? null : onAcao,
            child: _ocupado
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4))
                : Text(acao.toUpperCase()),
          ),
        ),
      ],
    );
  }

  Widget _telaResultado() {
    final r = _resultado;
    final ok = r?.combina == true;
    final pct = ((r?.similaridade ?? 0) * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor:
                (ok ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
            child: Icon(ok ? Icons.verified : Icons.gpp_maybe_outlined,
                size: 52, color: ok ? AppColors.success : AppColors.danger),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          ok ? 'Identidade verificada' : 'Não foi possível verificar',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          r?.erro ??
              (ok
                  ? 'O rosto da selfie corresponde ao do documento. Compatibilidade: $pct%.'
                  : 'O rosto da selfie não corresponde ao do documento (compatibilidade: $pct%). Refaça em local bem iluminado.'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 15),
        ),
        const Spacer(),
        if (ok)
          ElevatedButton(
            onPressed: _ocupado ? null : () => _salvar(verificada: true),
            child: _ocupado
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4))
                : const Text('CONCLUIR E SALVAR FOTO'),
          )
        else ...[
          ElevatedButton(
            onPressed: _ocupado ? null : _recomecar,
            child: const Text('TENTAR NOVAMENTE'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _ocupado ? null : () => _salvar(verificada: false),
            child: const Text('Usar a selfie sem verificação'),
          ),
        ],
      ],
    );
  }
}

/// Tela isolada de prova de vida (liveness) — pop(true) em sucesso.
class _ProvaDeVidaPage extends StatefulWidget {
  const _ProvaDeVidaPage();

  @override
  State<_ProvaDeVidaPage> createState() => _ProvaDeVidaPageState();
}

class _ProvaDeVidaPageState extends State<_ProvaDeVidaPage> {
  bool _fechando = false;

  void _finalizar(bool sucesso) {
    if (_fechando) return;
    _fechando = true;
    if (mounted) Navigator.pop(context, sucesso);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prova de vida')),
      body: FlutterFaceLiveness(
        actions: const [LivenessAction.blink, LivenessAction.smile],
        config: const LivenessConfig(
          randomizeActions: true,
          enableAntiSpoof: true,
          enableVideoReplayDetection: true,
        ),
        onSuccess: (result) => _finalizar(result.isSuccess),
        onFailed: (_) => _finalizar(false),
      ),
    );
  }
}
