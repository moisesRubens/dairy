# Name: api-data-handling
## Descrição: Padrões de consumo de API e Serialização.

- **Backend:** FastAPI (Python).
- **Serialização:** Models devem ter métodos `fromJson` e `toJson` compatíveis com a API.
- **Error Handling:** Tratar exceções Dio para erros 400 (Bad Request), 401 (Auth) e 500 (Server).
- **Padrão de Repositório:** Isolar chamadas de API em classes Repository.
- **Moeda:** Usar pacote `intl` para formatar faturamento e preços vindos da API.