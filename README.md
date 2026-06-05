# Joga 10

Aplicativo Flutter para organizar partidas, encontrar quadras, montar escalacoes,
acompanhar placares e interagir com outros jogadores.

## Arquitetura Atual

Esta versao do app usa uma arquitetura de MVP academico/local:

- Flutter como cliente principal.
- Repositorios Dart em `joga_10/lib/repositories/`.
- Conexao direta com PostgreSQL via package `postgres`.
- Sessao local com `shared_preferences`.
- Senhas armazenadas como hash BCrypt.

O backend Spring Boot antigo permanece fora do fluxo principal desta versao. Para
producao, o caminho recomendado e voltar a ter uma API entre o app e o banco,
mantendo credenciais e regras sensiveis no servidor.

## Estrutura

```text
joga_10/
  lib/
    app.dart
    db/
    model/
    pages/
    repositories/
    services/
    theme/
    util/
    widgets/
```

## Rodar o App

```powershell
cd joga_10
flutter pub get
flutter run
```

## Banco de Dados

Os scripts do banco ficam no diretorio `../db` do projeto completo. A ordem base
de execucao e:

```text
00_init -> 01_schema -> 02_seed -> 03_features -> 04_escalacao
-> 05_campeonatos -> 06_goleiros -> 07_placar -> 08_foto_elenco
```

Para Android Emulator, o host padrao em `lib/db/db_config.dart` e `10.0.2.2`.
Em celular fisico, altere para o IP da maquina na rede.
