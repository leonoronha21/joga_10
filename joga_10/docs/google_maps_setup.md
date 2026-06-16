# Google Maps

O app usa `google_maps_flutter`. As chaves ficam fora do repositório e devem
ser diferentes por plataforma, porque cada chave precisa de uma restrição de
aplicativo própria.

## Android

Defina localmente em `android/local.properties`:

```properties
maps.apiKey=SUA_CHAVE_ANDROID
```

Em CI, use a variável protegida `MAPS_API_KEY`. O Gradle injeta a chave no
Manifest durante o build e falha explicitamente se ela estiver ausente.

No Google Cloud Console, restrinja a chave:

- Restrição de aplicativo: **Android apps**
- Package name: `br.com.joga10.app`
- SHA-1 debug atual: `08:3C:FD:12:6A:25:FB:7E:12:14:FC:AA:92:42:09:FF:A1:FE:35:A0`
- Restrição de API: **Maps SDK for Android** e **Places SDK for Android**

Crie outra chave com o SHA-1 do certificado de release antes de publicar.

O mapa usa a Places SDK for Android (New) para descobrir locais esportivos por
texto e na área visível. Habilite a SDK no mesmo projeto Google Cloud. A busca
solicita somente tipos esportivos oficiais e limita cada consulta a 20 locais.

Antes de disponibilizar publicamente, conecte o Firebase App Check à Places SDK
e monitore as chamadas antes de ativar o enforcement.

## iOS e web

Use chaves separadas:

- iOS: restrita ao bundle ID `br.com.joga10.app` e à Maps SDK for iOS.
- Web: restrita aos domínios autorizados e à Maps JavaScript API.

Uma chave de Maps incluída em um app cliente pode ser extraída. A segurança
vem das restrições de aplicativo/API, limites de uso e monitoramento, não de
tratar a chave embarcada como um segredo de servidor.
