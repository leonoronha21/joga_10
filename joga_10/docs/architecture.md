# Arquitetura do Joga10

O projeto usa uma arquitetura em camadas, aplicada de forma incremental para
preservar os fluxos existentes.

## Dependencias

As dependencias devem apontar para dentro:

`pages -> application -> domain`

`repositories/services -> domain`

`core/app_dependencies.dart` e o ponto de composicao. Ele cria as
implementacoes concretas e as entrega ao restante do app.

## Responsabilidades

- `domain/contracts`: interfaces pequenas para banco, sessao e repositorios.
- `domain/services`: regras puras, sem Flutter, banco ou plugins.
- `application/use_cases`: orquestra fluxos de negocio usando contratos.
- `repositories` e `services`: integram PostgreSQL, SharedPreferences e plugins.
- `pages`: exibem estado, coletam entrada e delegam regras aos casos de uso.

## Regras para novas funcionalidades

1. Regra de negocio deve ficar em `domain/services` ou `application/use_cases`.
2. Paginas nao devem abrir conexoes ou executar SQL.
3. Integracoes externas devem implementar um contrato do dominio.
4. Novas dependencias concretas devem ser criadas apenas em
   `core/app_dependencies.dart`.
5. Casos de uso e servicos de dominio devem receber dependencias pelo
   construtor e possuir testes unitarios.

Essa separacao permite trocar o PostgreSQL direto por uma API/Firebase e o
pagamento local por um provedor real sem reescrever as telas.
