# Migracao Firebase Spark

Projeto Firebase: `joga10-ec65f`

## Estado atual

- Firestore criado em `southamerica-east1`, com free tier e protecao contra
  exclusao.
- Carga inicial com 30 documentos demonstrativos concluida.
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
- Uploads de fotos ficam desativados no Spark porque, desde 3 de fevereiro de
  2026, o Cloud Storage for Firebase exige o plano Blaze para manter acesso ao
  bucket. No Spark, chamadas ao Storage retornam erros 402 ou 403.
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
| Feed, posts e comentarios | PostgreSQL/local demo | Pendente |
| Amizades | PostgreSQL/local demo | Pendente |
| Campeonatos, clubes e confrontos | PostgreSQL/local demo | Pendente |
| Goleiros | PostgreSQL/local demo | Pendente |
| Dados cadastrais e foto | PostgreSQL/local demo | Pendente |
| Cartoes, rateios e pagamentos | PostgreSQL/local demo | Pendente |

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

1. Restringir alteracoes de partidas e membros ao organizador e ao proprio
   usuario. As regras demonstrativas atuais permitem update por qualquer
   usuario autenticado.
2. Substituir a sessao local por `FirebaseAuth` e IDs textuais.
3. Migrar os repositorios pendentes da matriz acima.
4. Configurar uma pagina publica e associacao de app links para o dominio
   `joga10.app`, permitindo convite para quem ainda nao instalou o app.
5. Ativar App Check antes de uma demonstracao publica.
