# Name: Interface Style (Estilo Paramount+)

## Descrição
Esta skill define a identidade visual do projeto, adotando uma estética de alto contraste, minimalista e moderna. Inspira-se na interface da Paramount+, mas adaptado para um tema claro (Light Mode) e focado em gestão de vendas.

## 1. Paleta de Cores (Sem Azul)
- **Fundo Principal (Canvas):** Branco Puro (`#FFFFFF`) para as áreas de conteúdo.
- **Fundo Secundário:** Cinza claríssimo (`#F8F8F8`) para separar secções ou fundos de ecrã.
- **Textos Primários:** Preto Profundo (`#000000`) para títulos e valores importantes.
- **Textos Secundários:** Cinza Médio (`#666666`) para labels e informações de suporte.
- **Destaque Funcional:** Verde Sucesso (`#2ECC71`) exclusivamente para indicadores de "Em Stock" ou faturamentos positivos.
- **Erros/Ações Críticas:** Vermelho sóbrio (`#E74C3C`) para botões de excluir ou erros de API.

## 2. Tipografia e Títulos
- **Família de Fontes:** Sans-serif moderna (ex: `Inter`, `Roboto` ou `Montserrat`).
- **Títulos (ex: "FAZER LOGIN"):** Texto em caixa alta (Uppercase), negrito, com espaçamento entre letras (letter-spacing) ligeiramente aumentado.
- **Hierarquia:** Diferenciar informações pelo peso da fonte (Bold/Regular) em vez de usar cores diferentes.

## 3. Componentes de Interface (UI)

### A. Campos de Entrada (Textboxes)
- **Estilo:** Campos retangulares com bordas muito finas (`1px`).
- **Borda Inativa:** Cinza claro (`#CCCCCC`).
- **Borda em Foco:** Preto (`#000000`) com espessura de `1.5px` a `2px`.
- **Raio de Borda (Radius):** 4px (quase reto, para um aspeto mais profissional).
- **Padding:** Espaçamento interno generoso para evitar que o texto toque nas bordas.

### B. Botões (Buttons)
- **Botão Primário (Continuar/Adicionar):** - Fundo: Preto (`#000000`).
  - Texto: Branco (`#FFFFFF`), Negrito, Caixa Alta.
  - Raio: 4px.
- **Botão Secundário (Editar/Parceiro):** - Fundo: Transparente.
  - Borda: `1px` Sólida Preta.
  - Texto: Preto.
- **Botão de Ação Crítica (Excluir):**
  - Texto em Vermelho, sem fundo ou com borda vermelha fina.

### C. Cards e Tabelas
- **Cards (Faturamento/Produtos):** Fundo branco, com uma sombra (shadow) extremamente subtil ou apenas uma borda de `0.5px` cinza. Evitar sombras pesadas.
- **Tabelas:** Linhas divisórias horizontais muito finas (`#EEEEEE`). Sem linhas verticais.

## 4. Diretrizes para o Copilot
- Ao gerar código Flutter, utiliza o `ThemeData` para centralizar estas cores.
- Para inputs, usa o decorador `OutlineInputBorder`.
- Garante que os botões ocupam a largura total em ecrãs de login (Full Width), mas são compactos em tabelas.
- Todos os links (como "Esqueceu a senha?") devem ser pretos com `FontWeight.w600`.