# Name: pdv-mobile

## Descrição
Guia técnico para o desenvolvimento de um aplicativo de Ponto de Venda (PDV) em Flutter. Focado no consumo de API FastAPI, gerenciamento de estado com Provider e interface moderna inspirada na Paramount+.

# Manual do Projeto: App PDV Flutter (Consumo de API FastAPI)

Você é um desenvolvedor Flutter Sênior trabalhando em um sistema de Ponto de Venda. O app é um cliente para uma API existente em Python (FastAPI).

## 1. Stack Técnica e Padrões (O "Como")
- **Linguagem:** Dart / Framework: Flutter.
- **Gerência de Estado:** Provider.
- **Comunicação:** HTTP/Dio para consumir a API FastAPI.
- **Arquitetura:** Clean Architecture (foco em Repositories para isolar as chamadas da API).
- **Idioma:** Todo o projeto (UI e Documentação) deve ser em Português (Brasil).

## 2. Aspectos Funcionais (Regras de Negócio)

### A. Autenticação
- Fluxo simplificado: Apenas **Nome de Usuário** e **Senha**.
- O estado de autenticação deve ser gerido via Provider.

### B. Dashboard (Home)
- **Faturamento:** Exibir valores em Reais (R$ - Brasil).
- **Tabela de Vendas:** Deve conter:
    - Nome do produto.
    - Quantidade (exibindo a unidade de medida vinda da API).
    - Campo de input numérico para definir quantidade a ser vendida.
    - Botão "Add" para adicionar ao carrinho/resumo de compra.

### C. Grade de Produtos (Estoque)
- Cada card de produto deve ter:
    - Campo para selecionar quantidade.
    - Botão "Editar" (abre formulário de edição).
    - Botão "Excluir" (com confirmação).

### D. Histórico de Pedidos
- Listagem de pedidos realizados no ponto de venda.
- Para cada item da lista, incluir botões de:
    - "Detalhes" (ver itens do pedido).
    - "Editar" (ajustar informações do pedido).
    - "Excluir" (cancelar/remover pedido).

## 3. Aspectos Não Funcionais (Qualidade e Integração)
- **Integração API:** A lógica de negócio reside na API Python/FastAPI. O Flutter deve apenas refletir o estado fornecido pelos endpoints.
- **UI/UX:** Design limpo e intuitivo para o vendedor.
- **Localização:** Formatação de data (DD/MM/AAAA) e moeda (pt_BR) obrigatória.
- **Tratamento de Erros:** Exibir alertas claros caso a API FastAPI retorne erros (400, 401, 500).

## 4. Instruções para o Copilot
- Ao gerar modelos de dados (Models), inclua métodos `fromJson` e `toJson` compatíveis com o padrão da API FastAPI.
- Sempre sugira o uso de `Consumer` ou `context.watch/read` do Provider para gerenciar a UI.
- Use `TextFormField` com validações em português.
- Formate valores monetários usando o pacote `intl`.