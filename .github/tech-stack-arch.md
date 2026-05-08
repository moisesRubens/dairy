# Name: tech-stack-arch
## Descrição: Definições de Stack, Pastas e Arquitetura para App de Laticínios.

- **Framework:** Flutter (Mobile) | **Linguagem:** Dart.
- **Estado:** Provider | **HTTP Client:** Dio (Consumindo FastAPI).
- **Idioma:** Código, UI e Documentação em Português (Brasil).
- **Localização:** Moeda (pt_BR, R$), Data (DD/MM/AAAA).

## Estrutura de Pastas (Arquitetura)
O projeto deve seguir estritamente a organização de pastas abaixo:

1. **domain/**: Modelos de dados (classes Plain Old Dart Objects) e entidades de negócio.
2. **service/**: Classes responsáveis pela comunicação direta com a API FastAPI usando Dio (Data Providers).
3. **controller/**: Lógica de estado (Providers). Fazem a ponte entre os Services e as Screens. 
4. **screens/**: Widgets de tela completa e componentes de UI (Views).

## Diretrizes de Implementação
- **Models:** Devem estar em `domain/` e conter métodos `fromJson` e `toJson`.
- **Services:** Devem estar em `service/` e tratar apenas a requisição HTTP e erro bruto.
- **Controllers:** Devem estar em `controller/`, estender `ChangeNotifier` e utilizar os Services para buscar dados.
- **Screens:** Devem estar em `screens/` e utilizar `Consumer` ou `context.watch` para reagir às mudanças no Controller.