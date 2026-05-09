# Name: routing-navigation
## Descrição: Padrões de Navegação Declarativa com GoRouter.

Este guia define como as trocas de tela devem ser feitas para garantir eficiência, suporte ao botão "Voltar" nativo e separação de responsabilidades.

## Configuração Técnica
- **Pacote:** `go_router`.
- **Estilo:** Navegação Declarativa (baseada em rotas).
- **Localização:** As rotas devem ser centralizadas em um arquivo `lib/routes.dart` ou dentro do `main.dart`.

## Estrutura de Rotas
- **Path-based:** Usar caminhos claros (ex: `/`, `/pedidos`, `/estoque`).
- **Navegação em Pilha:** Para telas que "sobrepõem" a Home (como Detalhes ou Pedidos), usar caminhos filhos ou `push` para que o botão voltar funcione automaticamente.
- **Transições:** Manter transições padrão do Material Design para consistência.

## Diretrizes de Implementação
1. **Definição:** Todas as `screens/` devem ser mapeadas no objeto `GoRouter`.
2. **Chamada na UI:** Usar `context.go('/caminho')` para trocar de aba e `context.push('/caminho')` quando quiser que a tela atual fique "embaixo" na pilha (permitindo voltar).
3. **Parâmetros:** Passar IDs e dados simples via caminhos (ex: `/pedidos/:id`).
4. **Navegação via Controller:** O `Controller` nunca deve navegar diretamente. Ele deve atualizar o estado, e a `Screen` reage usando o `GoRouter` baseada no sucesso da operação.

## Exemplo de Uso (Referência)
- Ir para pedidos: `context.push('/orders')` -> O botão voltar da AppBar aparece automaticamente.
- Voltar: `context.pop()` ou botão físico do Android.