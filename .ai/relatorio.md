

# Relatório Técnico: Backend Dairy Management (FastAPI)

Este documento descreve a estrutura, tecnologias e fluxo de trabalho da API para facilitar a integração com o front-end em Flutter.

## 🚀 Tecnologias e Ferramentas

- **Framework:** FastAPI (Python)
- **Banco de Dados:** SQLite (arquivo `dairy_database.db`)
- **ORM:** SQLAlchemy
- **Migrações:** Alembic
- **Autenticação:** OAuth2 com Password Flow (Bearer Token)
- **Serialização/Validação:** Pydantic v2

## 🏗️ Estrutura do Projeto

O projeto segue uma arquitetura separada por domínios, facilitando a manutenção:

- `/app/model.py`: Definições das tabelas do banco de dados.
- `/app/[domínio]/[domínio]_routes.py`: Definição dos endpoints (URLs).
- `/app/[domínio]/[domínio]_controller.py`: Orquestração entre rotas e serviços.
- `/app/[domínio]/[domínio]_service.py`: Lógica de negócio e acesso ao banco.
- `/app/[domínio]/[domínio]_schema.py`: DTOs (Data Transfer Objects) para entrada e saída de dados.

## 🔐 Fluxo de Autenticação

A API utiliza autenticação via Token. Para acessar a maioria dos recursos, o app Flutter deve:

1. **Login:** Fazer um POST em `/auth/login` enviando `username` e `password` (form-data).
2. **Token:** Armazenar o `access_token` retornado.
3. **Headers:** Enviar em todas as requisições protegidas o cabeçalho: 
   `Authorization: Bearer <seu_token>`

## 🛣️ Principais Endpoints para o Flutter

### 1. Autenticação e Pontos de Venda (`/auth`)
| Método | Rota | Descrição |
|---|---|---|
| POST | `/auth/login` | Realiza login e retorna o token. |
| POST | `/auth/` | Cadastra um novo Ponto de Venda. |
| GET | `/auth/` | Lista todos os pontos de venda (Admin). |
| GET | `/auth/{id}/outbounds` | Lista retiradas de um ponto específico. |
| POST | `/auth/{id}/outbounds` | Registra uma nova retirada de produtos. |

### 2. Produtos (`/products`)
| Método | Rota | Descrição |
|---|---|---|
| GET | `/products/` | Lista todos os produtos no estoque. |
| POST | `/products/` | Adiciona novo produto (nome, preço, estoque). |
| GET | `/products/{id}` | Detalhes de um produto específico. |
| PATCH | `/products/{id}` | Atualiza dados/estoque do produto. |
| DELETE | `/products/{id}` | Remove um produto. |

### 3. Pedidos (`/pedidos`)
| Método | Rota | Descrição |
|---|---|---|
| GET | `/pedidos/` | Lista pedidos (filtros por data/status). |
| PATCH | `/pedidos/{id}` | Atualiza um pedido existente. |
| DELETE | `/pedidos/{id}` | Remove um pedido. |

### 4. Retiradas/Saídas (`/outbounds`)
| Método | Rota | Descrição |
|---|---|---|
| PATCH | `/outbounds/{id}` | Edita detalhes de uma retirada. |
| PATCH | `/outbounds/{id}/quantity` | Atualiza apenas a quantidade retirada. |

## 📦 Formatos de Dados (Exemplos)

### Criar Produto (POST `/products/`)
```json
{
  "name": "Leite Integral",
  "price": 5.50,
  "amount": 100,
  "kg": null,
  "liters": null
}
```
*Nota: Use `amount` para unidades, `kg` para peso ou `liters` para volume.*

### Registrar Retirada (POST `/auth/{id}/outbounds`)
```json
{
  "produtos": [
    {
      "product_id": 1,
      "quantidade": 10,
      "unidade": "amount"
    }
  ],
  "observacao": "Carga matutina"
}
```

## ⚙️ Workflow de Desenvolvimento

1. **Migrações:** Se houver mudanças no banco, execute:
   `alembic upgrade head`
2. **Execução:** O backend geralmente roda em `http://localhost:8000`.
3. **CORS:** A API já está configurada para aceitar requisições de `http://localhost:5173` e outras portas comuns de desenvolvimento web/mobile.

## 🛠️ Dicas para o Flutter

- **Base URL:** Configure uma constante para a URL base (ex: `10.0.2.2:8000` para o emulador Android).
- **Models:** Utilize o site app.quicktype.io para converter os JSONs acima em classes Dart rapidamente.
- **Tratamento de Erros:** A API retorna `404` para itens não encontrados, `409` para conflitos (ex: produto já existe) e `400` para erros de validação.

---
*Documentação gerada para auxílio na integração do front-end Flutter.*

