/// Configuração do Google Pay em ambiente de **TESTE**.
///
/// Usa o gateway de exemplo do Google (`example`), então nenhum valor real é
/// movimentado — é uma demonstração. Para produção, troque `environment` para
/// `PRODUCTION`, informe o gateway/PSP real (ex.: stripe, mercadopago) e o
/// `gatewayMerchantId`, e registre o app no Google Pay Business Console.
const String googlePayConfigJson = '''
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "exampleGatewayMerchantId"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD", "ELO"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": false
        }
      }
    ],
    "merchantInfo": {
      "merchantName": "Joga10 (Demonstracao)"
    },
    "transactionInfo": {
      "countryCode": "BR",
      "currencyCode": "BRL"
    }
  }
}
''';
