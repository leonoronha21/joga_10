import 'package:joga_10/model/Monetizacao.dart';

class BeneficiosAssinatura {
  static const double taxaRateioFree = 0;
  static const double taxaRateioPro = 0;

  const BeneficiosAssinatura();

  bool assinaturaProAtiva(AssinaturaUsuario? assinatura) {
    return assinatura?.ativa == true && assinatura?.plano.codigo == 'PRO';
  }

  double taxaRateio(AssinaturaUsuario? assinatura) {
    return 0;
  }

  bool podeAcessarCampeonatos(AssinaturaUsuario? assinatura) {
    return true;
  }
}
