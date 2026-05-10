# DNA do Projeto: Fazenda Boa Esperança (PDV Mobile)

## 1. Padrões de UI/UX (Design System)
- **Paleta de Cores:**
  - **Primária:** Preto (`Colors.black`) para AppBar, Cards de métricas, botões principais e bordas de destaque.
  - **Destaque de Sucesso:** Verde (`Color(0xFF2E7D32)`) para valores monetários positivos e ações de finalização.
  - **Alerta/Erro:** Vermelho (`Color(0xFFE74C3C)`) para ações de exclusão ou cancelamento.
  - **Informativo/Status:** Laranja (`Colors.orange[800]`) para pendências. Badges de status usam a cor base com `opacity(0.1)` no fundo.
  - **Neutros:** Branco (`Colors.white`) para fundos de tela; Cinza claro (`Colors.grey[100/300]`) para fundos de tabelas e bordas.
- **Espaçamento e Layout:**
  - Padding padrão de tela: `16.0` (all).
  - Espaçamento entre seções: `SizedBox(height: 20)`.
  - Bordas: `borderRadius: BorderRadius.circular(16)` para cards de produtos em grade, `12` para cards de faturamento e `8` para tabelas/inputs.
  - Sombras: `boxShadow` sutil em cards brancos (`Colors.black.withOpacity(0.05)`, blur 10).
- **Tipografia:**
  - Títulos de seção: Bold, tamanho 18.
  - Labels de cards: Uppercase, tamanho 10-12, cinza.
  - Métricas (Revenue): Bold, tamanho 32, cor Branca sobre fundo Preto.
  - Formatação Monetária: Padrão `R$ 0,00` via `.toStringAsFixed(2).replaceAll('.', ',')`.

## 2. Arquitetura de Código (Shell & Body)
- **Estrutura Base (Shell):** O `main.dart` utiliza um `MainShell` com `Scaffold` fixo contendo `AppBar`, `Drawer` e `BottomNavigationBar`.
- **Navegação:** Uso de `IndexedStack` para persistência de estado entre abas.
- **Organização de Telas:** As telas (screens) retornam o conteúdo do body sem `Scaffold` próprio.
  - *Regra de Scroll:* Usar `SingleChildScrollView` como raiz para telas simples.
  - *Regra de Painel Fixo:* Telas com `BottomActionPanel` (Estoque/PDV) devem usar `Column` -> `Expanded` (com scroll interno) -> `Widget Fixo`.
- **Estado:** Atualmente utilizando `setState` local, mas estruturado para fácil migração para `Provider`.

## 3. Biblioteca de Componentes Customizados
- **RevenueCard:** Container preto, texto branco, métrica em destaque.
- **DataTableContainer:** Fundo branco, borda cinza (8px), cabeçalho `Grey[100]` com labels em negrito (tamanho 11).
- **ProductRow:** (Home) Linha para PDV com input de quantidade e botão "Add".
- **ProductCard:** (Inventory) Card em grade (16px radius) com imagem, checkbox de seleção (com interceptação de clique) e expansão de ações (Editar/Excluir).
- **CartItemRow:** Linha de item no carrinho com `Icons.delete_outline`.
- **BottomActionPanel:** Barra preta fixa/inferior para ações em lote (ex: definir quantidade).
- **StatusBadge:** Container pequeno com bordas de 4px, cores semitransparentes no fundo e texto em negrito (tamanho 10) para estados (Finalizado, Pendente, etc).
- **PaginationControls:** Conjunto de botões `OutlinedButton` pretos e texto "Página X de Y" centralizado.

## 4. Convenções de Escrita e Nomenclatura
- **Métodos de Build:** Divisão da UI em métodos privados dentro da State class (ex: `_buildRevenueCard()`, `_buildProductTable()`).
- **Componentização:** Widgets reutilizáveis (como `ProductRow`) definidos como classes `StatelessWidget` fora da classe principal do arquivo, mas no mesmo arquivo quando específicos daquela tela.
- **Inputs:** Uso de `TextEditingController` e `FocusNode`.
  - Inputs numéricos: `keyboardType: TextInputType.number`.
  - Foco: Ações de "Adicionar" ou ícones de teclado em painéis inferiores devem disparar `focusNode.requestFocus()`.

## 5. Elementos de Feedback
- **SnackBars:** Utilizados para confirmar ações rápidas (ex: "Produto adicionado").
- **Dialogs:** Confirmações críticas (Excluir/Sair) com botões em Caps Lock (CANCELAR em preto, EXCLUIR em vermelho).
- **Icons:** Uso preferencial de versões `_outlined` para estados inativos e preenchidos para estados ativos.
- **Menus de Ação:** Uso de `PopupMenuButton` (ícone `more_vert_outlined`, tamanho 20) com opções contendo ícone (tamanho 18) e texto.
```

<!--
[PROMPT_SUGGESTION]Crie a estrutura básica da tela de Estoque (InventoryPage) seguindo esse novo extractor.md[/PROMPT_SUGGESTION]
[PROMPT_SUGGESTION]Como posso refatorar a HomePage para usar o Provider conforme sugerido na arquitetura?[/PROMPT_SUGGESTION]
->
