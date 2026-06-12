import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

import 'package:joga_10/config/google_pay_config.dart';
import 'package:joga_10/model/Cartao.dart';
import 'package:joga_10/pages/cadastro_cartao_page.dart';
import 'package:joga_10/repositories/cartao_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class CartoesPage extends StatefulWidget {
  const CartoesPage({super.key});

  @override
  State<CartoesPage> createState() => _CartoesPageState();
}

class _CartoesPageState extends State<CartoesPage> {
  final _repo = CartaoRepository();
  late Future<List<Cartao>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Cartao>> _carregar() async {
    final id = await Sessao.instance.usuarioId;
    if (id == null) return [];
    return _repo.listarPorUsuario(id);
  }

  void _recarregar() => setState(() {
        _futuro = _carregar();
      });

  Future<void> _adicionar() async {
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CadastroCartaoPage()),
    );
    if (criou == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus cartões')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionar,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: Column(
        children: [
          _secaoGooglePay(),
          const Divider(height: 1),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    return FutureBuilder<List<Cartao>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final cartoes = snap.data ?? [];
        if (cartoes.isEmpty) {
          return EmptyState(
            icone: Icons.credit_card,
            titulo: 'Nenhum cartão',
            mensagem: 'Adicione um cartão para agilizar os pagamentos.',
            acao: ElevatedButton(
              onPressed: _adicionar,
              child: const Text('Adicionar cartão'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: cartoes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _CartaoVisual(cartao: cartoes[i]),
        );
      },
    );
  }

  Widget _secaoGooglePay() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Pagamento rápido',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pague com o Google Pay (ambiente de teste — nenhum valor real é cobrado).',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          GooglePayButton(
            paymentConfiguration:
                PaymentConfiguration.fromJsonString(googlePayConfigJson),
            paymentItems: const [
              PaymentItem(
                label: 'Joga10',
                amount: '5.00',
                status: PaymentItemStatus.final_price,
              ),
            ],
            type: GooglePayButtonType.pay,
            onPaymentResult: _onGooglePayResult,
            loadingIndicator: const Center(
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
            onError: (_) =>
                _msg('Google Pay indisponível neste dispositivo.'),
          ),
        ],
      ),
    );
  }

  void _onGooglePayResult(Map<String, dynamic> result) {
    _msg('Pagamento via Google Pay aprovado (demonstração).');
  }

  void _msg(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }
}

class _CartaoVisual extends StatelessWidget {
  final Cartao cartao;
  const _CartaoVisual({required this.cartao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.contactless, color: Colors.white),
              Text(
                cartao.bandeira ?? '',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            cartao.mascarado,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cartao.nomeTitular.toUpperCase(),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              Text(
                cartao.validade,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
