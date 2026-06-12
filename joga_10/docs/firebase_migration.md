# Migracao Firebase Spark

Projeto Firebase: `joga10-ec65f`

## Estado atual

- Firestore criado em `southamerica-east1`, com free tier e protecao contra
  exclusao.
- Carga demonstrativa (`tool/seed_firestore_demo.mjs`): 50 documentos —
  usuarios, estabelecimentos (Porto Alegre-RS), quadras, partidas/membros, e
  uma liga com 4 clubes + confrontos REALIZADOS (classificação) + elenco e 2
  goleiros disponíveis.
- Regras do cliente fechadas e indices publicados.
- Firebase inicializado no Flutter.
- Login Google implementado no Flutter, com SHA-1/SHA-256 de debug cadastrados.
- Provedor Google habilitado no Firebase e arquivos OAuth Android/iOS
  atualizados no projeto.
- Login Google, perfil basico, estabelecimentos, quadras, partidas, membros,
  escalacao e gols ja usam Firestore quando existe uma sessao Firebase.
- O login local `admin` / `123` continua usando dados locais/PostgreSQL.
- O app usa uma camada temporaria de compatibilidade que converte IDs textuais
  do Firestore em inteiros deterministas durante a execucao. Os documentos
  continuam usando IDs textuais no Firestore.

## Decisoes do MVP

- O ambiente contem somente dados de demonstracao.
- IDs numericos do PostgreSQL nao serao preservados.
- Novos documentos usam IDs textuais do Firestore.
- Com o plano **Blaze** ativo, as imagens (foto de perfil e posts) agora vão
  para o **Firebase Cloud Storage** (`FirebaseMediaStorage`), salvando só a URL
  no Firestore. Regras em `storage.rules` (escrita restrita ao próprio uid).
  ⚠️ Pré-requisito único: ativar o Storage no console
  (`console.firebase.google.com/project/joga10-ec65f/storage` → "Get Started")
  e então `firebase deploy --only storage`.
- **Verificação de identidade (KYC/biometria):** foto do documento (CNH/RG) →
  prova de vida (liveness) → **face match 1:1** documento × selfie
  (MobileFaceNet do `flutter_face_liveness` + ML Kit; comparação de embeddings
  por cosseno, 100% no dispositivo). O documento NÃO é armazenado (privacidade);
  em caso de match, a selfie vira a foto de perfil verificada
  (`fotoVerificada` + `faceMatchScore`). Limiar calibrável em `BiometriaFacial`.
- Pagamentos continuam simulados, mas passam por um contrato de provedor.
- Firebase Authentication e as regras das colecoes migradas estao publicados.
- App Check ativado no cliente mobile (debug em desenvolvimento, Play Integrity
  no Android release e App Attest/DeviceCheck no iOS). Antes da demo pública,
  registrar os apps e habilitar enforcement no console.
- Para semear uma amizade aceita entre o usuário Google de teste e o perfil
  demo, execute o seed com `DEMO_USER_UID` definido para o uid desse usuário.
- Pagamentos continuam simulados, mas passam por um contrato de provedor.
- Firebase Authentication e as regras das colecoes migradas estao publicados.

## Cobertura atual por fluxo

| Fluxo | Fonte com login Google | Situacao |
| --- | --- | --- |
| Autenticacao Google e perfil basico | Firebase Auth + `usuarios` | Conectado |
| Locais e mapa | `estabelecimentos` | Conectado; atualizar tela para reler |
| Quadras | `quadras` | Conectado |
| Partidas, convidados, escalacao e gols | `partidas/{id}/membros` | Conectado |
| Convite por contato | Agenda do aparelho + WhatsApp | Conectado no Android |
| Feed, posts, curtidas e comentarios | `postagens` (+ `comentarios`) | Conectado; imagem via Firebase Storage |
| Amizades | `amizades` (par de uids) | Conectado |
| Campeonatos, ligas, clubes e confrontos | `clubes`/`ligas`/`ligaClubes`/`confrontos`/`clubeJogadores` | Conectado |
| Goleiros e contratações | `goleiros/{uid}` + `contratacoesGoleiro` | Conectado |
| Foto de perfil + verificação (documento → liveness → face match) | Firebase Storage + `usuarios.fotoUrl`/`fotoVerificada` | Conectado (requer Storage ativo) |
| Dados cadastrais | `usuarios/{uid}` privado + ViaCEP | Conectado |
| Rateio (divisão de custos) | `rateios/{partidaId}` + `cobrancas` | Conectado |
| Pagamentos | `PagamentoDemoProvider` + Google Pay (TEST) | Simulado |
| Cartoes (dados cadastrais) | `cartoes/{uid}/itens` | Conectado; somente dados PCI seguros |

O Android nao permite que o app liste diretamente apenas os contatos do
WhatsApp. O fluxo atual abre o seletor de contatos do aparelho e, depois da
escolha, abre a conversa daquele numero no WhatsApp com o link da partida.

## Impacto de desativar fotos

Partidas, locais, quadras, rateios, assinaturas demonstrativas e posts de texto
continuam funcionando. Ficam indisponiveis:

- envio e troca da foto de perfil;
- persistencia do resultado da verificacao facial;
- criacao de posts com imagem.

Nao devem ser gravados bytes ou imagens em base64 no Firestore. Quando uploads
forem habilitados, uma implementacao de `MediaStorageContract` deve enviar o
arquivo para um servico de objetos e salvar apenas URL, tipo e metadados no
Firestore.

## Modelo inicial do Firestore

| Colecao | Conteudo principal |
| --- | --- |
| `usuarios` | perfil publico, contato, cidade, role e status |
| `estabelecimentos` | dados do local, endereco, horario e coordenadas |
| `quadras` | estabelecimento relacionado, modalidade e preco |
| `partidas` | organizador, quadra, local, horario, formato e status |
| `partidas/{id}/membros` | usuario, nome exibido, equipe, posicao e gols |
| `rateios` | partida, valores, taxa e status |
| `rateios/{id}/cobrancas` | usuario, valor e estado do pagamento |
| `pagamentoTransacoes` | projecao/auditoria retornada pelo backend de pagamento |
| `configuracoes` | versao do schema e marcadores da carga demonstrativa |

Relacionamentos sao guardados com o ID textual do documento relacionado. Dados
de exibicao que mudam pouco, como nome do local na partida, podem ser
duplicados para reduzir leituras no Spark.

O codigo atual ainda possui IDs numericos espalhados por modelos, contratos,
deep links e repositorios. `FirestoreCompatIds` e uma ponte temporaria para
permitir a migracao gradual. A solucao definitiva continua sendo trocar os IDs
do dominio por strings e remover essa camada.

## Pagamentos futuros

`PagamentoProviderContract` separa o dominio do provedor. No MVP,
`PagamentoDemoProvider` aprova a operacao sem movimentar dinheiro.

Uma integracao real com banco, Open Finance ou gateway deve ser implementada
em backend externo:

1. o app solicita uma cobranca ao backend;
2. o backend usa credenciais secretas do provedor;
3. webhooks confirmam ou rejeitam o pagamento;
4. o backend atualiza a transacao e a cobranca no Firestore;
5. o app apenas consulta o status.

Credenciais bancarias e confirmacao de pagamento nunca devem ficar no Flutter.
Como o plano Spark nao inclui Cloud Functions, essa integracao futura deve usar
o backend existente ou outro servico externo.

## Proximas liberacoes de seguranca

1. (FEITO) Alteracoes de partidas e membros restritas ao organizador e ao
   proprio usuario. `partidas`: create/update apenas pelo organizador.
   `partidas/{id}/membros`: create/update apenas pelo organizador ou pelo
   proprio usuario. Para evitar `get()` dentro de um batch (a partida ainda
   nao existe no commit) o campo `organizadorId` e denormalizado em cada
   membro. Observacao: partidas semeadas (seed) pertencem a um uid de demo, de
   modo que outros usuarios as leem mas nao as editam; partidas criadas pelo
   usuario logado funcionam por completo.
2. Substituir a sessao local por `FirebaseAuth` e IDs textuais.
3. (FEITO) Escritas comunitarias exigem proprietário, curtidas só alteram o
   próprio uid e a busca social usa `usuariosPublicos` sem e-mail/endereço.
4. Remover `FirestoreCompatIds` e migrar os modelos/deep links de `int` para
   `String`; ainda há varreduras O(n) enquanto essa compatibilidade existir.
5. Configurar uma pagina publica e associacao de app links para o dominio
   `joga10.app`, permitindo convite para quem ainda nao instalou o app.
6. Registrar os providers e habilitar enforcement do App Check no console.
7. Calibrar o limiar do face match em aparelhos reais e ativar Phone Auth.
8. Retirar o PostgreSQL dos fluxos locais restantes e conectar pagamentos reais
   somente por backend/webhooks.
