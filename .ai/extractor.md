# DNA do Projeto: Fazenda Boa Esperança (PDV Mobile)

## 1. Padrões de UI/UX (Design System)
- **Paleta de Cores:**
  - **Primária:** Preto (`Colors.black`) para elementos de destaque como AppBar, Cards de métricas e itens selecionados.
  - **Destaque de Sucesso:** Verde (`Color(0xFF2E7D32)`) para valores monetários positivos e ações de finalização.
  - **Neutros:** Branco (`Colors.white`) para fundos de tela; Cinza claro (`Colors.grey[100/300]`) para fundos de tabelas e bordas.
- **Espaçamento e Layout:**
  - Padding padrão de tela: `16.0` (all).
  - Espaçamento entre seções: `SizedBox(height: 20)`.
  - Bordas: `borderRadius: BorderRadius.circular(12)` para cards principais e `8` para containers de tabelas.
- **Tipografia:**
  - Títulos de seção: Bold, tamanho 18.
  - Métricas (Revenue): Bold, tamanho 32, cor Branca sobre fundo Preto.
  - Formatação Monetária: `R$ 0,00` (substituindo '.' por ',').

## 2. Arquitetura de Código (Shell & Body)
- **Estrutura Base (Shell):** O `main.dart` utiliza um `MainShell` com `Scaffold` fixo contendo `AppBar`, `Drawer` e `BottomNavigationBar`.
- **Navegação:** Uso de `IndexedStack` para persistência de estado entre abas.
- **Organização de Telas:** As telas (screens) não possuem `Scaffold` próprio; elas retornam um `SingleChildScrollView` com padding interno para garantir rolagem.
- **Estado:** Atualmente utilizando `setState` local, mas estruturado para fácil migração para `Provider`.

## 3. Biblioteca de Componentes Customizados
- **Cards de Destaque:** Containers pretos com texto branco e bordas arredondadas (12px).
- **Tabelas de Dados:** Containers brancos com borda cinza, utilizando cabeçalhos com `Colors.grey[100]`.
- **ProductRow:** Componente de linha customizado para inputs de venda, com `TextField` centralizado e `isDense: true`.
- **CartItemRow:** Componente de linha para itens no carrinho com ação de remoção (`Icons.delete_outline`).

## 4. Convenções de Escrita e Nomenclatura
- **Métodos de Build:** Divisão da UI em métodos privados dentro da State class (ex: `_buildRevenueCard()`, `_buildProductTable()`).
- **Componentização:** Widgets reutilizáveis (como `ProductRow`) definidos como classes `StatelessWidget` fora da classe principal do arquivo, mas no mesmo arquivo quando específicos daquela tela.
- **Inputs:** Uso de `TextEditingController` para capturar quantidades, com `keyboardType` numérico e decimal.

## 5. Elementos de Feedback
- **SnackBars:** Utilizados para confirmar ações rápidas (ex: "Produto adicionado").
- **Dialogs:** Previstos para confirmações críticas (excluir/finalizar).
```

<!--
[PROMPT_SUGGESTION]Crie a estrutura básica da tela de Estoque (InventoryPage) seguindo esse novo extractor.md[/PROMPT_SUGGESTION]
[PROMPT_SUGGESTION]Como posso refatorar a HomePage para usar o Provider conforme sugerido na arquitetura?[/PROMPT_SUGGESTION]
->
