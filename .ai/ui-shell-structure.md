# Name: ui-shell-structure
## Descrição: Estrutura Visual Fixa e Layout Base (Shell) do App.

Este guia define que a interface deve ser dividida em um "Shell" (moldura fixa) e o "Body" (conteúdo variável), garantindo que AppBar, BottomNavigationBar e Drawer sejam persistentes e consistentes em todas as telas.

## 1. O Padrão "Shell" (Estilo Paramount+)
- **AppBar Fixa:** Fundo Preto (#000000), Texto Branco, borda inferior fina em Cinza Escuro (#424242).
- **Drawer:** Deve conter o perfil do usuário e configurações, acessível de qualquer tela.
- **BottomNavigationBar:** Deve ser o controlador principal de navegação entre as seções: Home, Pedidos, Estoque e Perfis.
- **Cor de Destaque:** Verde Sucesso (#2E7D32) para itens selecionados e botões de ação positiva.

## 2. Regras de Geração de Telas
Sempre que uma nova tela (Home, Orders, Inventory, Profiles) for gerada, ela deve seguir estas regras:
- **Não repetir o Scaffold completo:** A tela deve retornar apenas o conteúdo do `body` ou ser injetada dentro de um `ShellWidget`.
- **Navegação com GoRouter:** Usar `StatefulShellRoute` para que a barra inferior não "pisque" ou desapareça ao trocar de aba.
- **Independência de Body:** O conteúdo de cada tela deve ser um `SingleChildScrollView` ou `ListView` para garantir a rolagem, já que a AppBar e a BottomBar são fixas.

## 3. Componentização Visual
- **Cards de Faturamento:** Sempre fundo preto com texto branco (contraste máximo).
- **Tabelas/Grades:** Fundo branco, bordas arredondadas (8px) e linhas separadas por cores leves (Grey[100]).
- **Inputs de Quantidade:** Bordas quadradas/leves (4px), alinhamento centralizado.