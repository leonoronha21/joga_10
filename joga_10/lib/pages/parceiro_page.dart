import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/services/via_cep_service.dart';
import 'package:joga_10/theme/app_colors.dart';

class ParceiroPage extends StatefulWidget {
  const ParceiroPage({super.key});

  @override
  State<ParceiroPage> createState() => _ParceiroPageState();
}

class _ParceiroPageState extends State<ParceiroPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = EstabelecimentoRepository();
  final _viaCep = ViaCepService();

  final _nome = TextEditingController();
  final _cnpj = TextEditingController();
  final _razao = TextEditingController();
  final _cidade = TextEditingController();
  final _cep = TextEditingController();
  final _rua = TextEditingController();
  final _bairro = TextEditingController();
  final _numero = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _abertura = TextEditingController();
  final _fechamento = TextEditingController();

  bool _salvando = false;
  bool _buscandoCep = false;

  GoogleMapController? _mapController;
  LatLng? _local;
  bool _obtendoGps = false;

  static const LatLng _centroPadrao =
      LatLng(-30.0346, -51.2177); // Porto Alegre

  Future<void> _usarMinhaLocalizacao() async {
    setState(() => _obtendoGps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _msgGps('Ative a localização do aparelho.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _msgGps('Permissão de localização negada.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() => _local = p);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: p, zoom: 16)),
      );
    } catch (_) {
      _msgGps('Não foi possível obter a localização.');
    } finally {
      if (mounted) setState(() => _obtendoGps = false);
    }
  }

  void _msgGps(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  void dispose() {
    _mapController?.dispose();
    for (final c in [
      _nome,
      _cnpj,
      _razao,
      _cidade,
      _cep,
      _rua,
      _bairro,
      _numero,
      _telefone,
      _email,
      _abertura,
      _fechamento,
    ]) {
      c.dispose();
    }
    _viaCep.dispose();
    super.dispose();
  }

  String? _vazioParaNull(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _buscarCep() async {
    if (_buscandoCep) return;
    setState(() => _buscandoCep = true);
    try {
      final endereco = await _viaCep.buscar(_cep.text);
      if (!mounted) return;
      if (endereco == null) {
        _msgGps('CEP não encontrado.');
        return;
      }
      setState(() {
        _cep.text = endereco.cep;
        _cidade.text = endereco.cidade;
        _bairro.text = endereco.bairro;
        _rua.text = endereco.logradouro;
      });
    } catch (_) {
      if (mounted) _msgGps('Não foi possível consultar o CEP.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await _repo.salvar(
        nome: _nome.text,
        cnpj: _vazioParaNull(_cnpj.text),
        razaoSocial: _vazioParaNull(_razao.text),
        cidade: _vazioParaNull(_cidade.text),
        cep: _vazioParaNull(_cep.text),
        rua: _vazioParaNull(_rua.text),
        bairro: _vazioParaNull(_bairro.text),
        numero: _vazioParaNull(_numero.text),
        telefone: _vazioParaNull(_telefone.text),
        email: _vazioParaNull(_email.text),
        horaAbertura: _vazioParaNull(_abertura.text),
        horaFechamento: _vazioParaNull(_fechamento.text),
        latitude: _local?.latitude,
        longitude: _local?.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Estabelecimento enviado! Aguarde aprovação.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cadastrar estabelecimento.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Torne-se parceiro')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Cadastre seu estabelecimento e disponibilize suas quadras no Joga 10.',
              style: TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            _campo(_nome, 'Nome do estabelecimento',
                icon: Icons.storefront_outlined, obrigatorio: true),
            _campo(_cnpj, 'CNPJ', icon: Icons.badge_outlined),
            _campo(_razao, 'Razão social', icon: Icons.business_outlined),
            _campo(_telefone, 'Telefone',
                icon: Icons.phone_outlined, tipo: TextInputType.phone),
            _campo(_email, 'Email',
                icon: Icons.mail_outline, tipo: TextInputType.emailAddress),
            Row(
              children: [
                Expanded(
                    child: _campo(_abertura, 'Abertura (HH:MM)',
                        icon: Icons.schedule)),
                const SizedBox(width: 12),
                Expanded(
                    child: _campo(_fechamento, 'Fechamento (HH:MM)',
                        icon: Icons.schedule)),
              ],
            ),
            _campo(_cidade, 'Cidade', icon: Icons.location_city_outlined),
            _campo(
              _cep,
              'CEP',
              icon: Icons.markunread_mailbox_outlined,
              tipo: TextInputType.number,
              onEditingComplete: _buscarCep,
              suffixIcon: IconButton(
                onPressed: _buscandoCep ? null : _buscarCep,
                icon: _buscandoCep
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                tooltip: 'Buscar CEP',
              ),
            ),
            _campo(_rua, 'Rua', icon: Icons.signpost_outlined),
            _campo(_bairro, 'Bairro', icon: Icons.map_outlined),
            _campo(_numero, 'Número', icon: Icons.numbers),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Localização no mapa',
                    style: TextStyle(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _obtendoGps ? null : _usarMinhaLocalizacao,
                  icon: _obtendoGps
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: const Text('Usar minha localização'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _local == null
                  ? 'Toque no mapa para marcar o ponto.'
                  : 'Ponto: ${_local!.latitude.toStringAsFixed(5)}, ${_local!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _local ?? _centroPadrao,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (point) => setState(() => _local = point),
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  markers: _local == null
                      ? const {}
                      : {
                          Marker(
                            markerId: const MarkerId('local-parceiro'),
                            position: _local!,
                          ),
                        },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('CADASTRAR ESTABELECIMENTO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    IconData? icon,
    TextInputType? tipo,
    bool obrigatorio = false,
    VoidCallback? onEditingComplete,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        onEditingComplete: onEditingComplete,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: suffixIcon,
        ),
        validator: obrigatorio
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }
}
