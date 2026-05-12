```python
# Conteúdo do arquivo Markdown atualizado com Nome e Descrição
skill_md_content = """# Skill: Integração de Autenticação Bearer Token no Flutter

**Descrição:** Esta skill detalha o workflow técnico para implementar a autenticação JWT (Bearer Token) em aplicações Flutter integradas ao backend FastAPI. Ela aborda desde a captura das credenciais em formato form-data até a persistência segura do token e sua inclusão nos cabeçalhos das requisições para endpoints protegidos.

---

## 1. Visão Geral do Workflow

O processo de autenticação segue o fluxo padrão de **OAuth2 Password Flow**:
1.  **Autenticação**: O app envia credenciais (`username` e `password`) para o endpoint `/auth/login`.
2.  **Armazenamento**: O `access_token` retornado é salvo localmente no dispositivo.
3.  **Autorização**: O token é anexado ao cabeçalho `Authorization` em todas as requisições subsequentes a rotas protegidas.

## 2. Requisitos (pubspec.yaml)

Adicione as seguintes dependências ao seu projeto:
- `http`: Para realizar requisições REST.
- `shared_preferences`: Para armazenar o token de forma persistente.


```

```text
Traceback (most recent call last):
  File "<xbox-string>", line 151
    html_content = f"""
<html>
<head>
<style>
    @page {{
        size: A4;
        margin: 20mm;
        background-color: #ffffff;
    }}
    body {{
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        line-height: 1.6;
        color: #333;
    }}
    h1 {{ color: #2c3e50; border-bottom: 2px solid #eee; padding-bottom: 10px; }}
    h2 {{ color: #2980b9; margin-top: 30px; border-left: 5px solid #2980b9; padding-left: 10px; }}
    h3 {{ color: #34495e; }}
    code {{
        background-color: #f4f4f4;
        padding: 2px 5px;
        border-radius: 3px;
        font-family: monospace;
    }}
    pre {{
        background-color: #f8f9fa;
        padding: 15px;
        border: 1px solid #ddd;
        border-radius: 5px;
        overflow-x: auto;
    }}
    .note {{
        background-color: #e7f3fe;
        border-left: 6px solid #2196F3;
        padding: 10px;
        margin: 20px 0;
    }}
</style>
</head>
<body>
    {md_content.replace('# ', '<h1>').replace('## ', '<h2>').replace('### ', '<h3>').replace('```dart', '<pre>').replace('```yaml', '<pre>').replace('```', '</pre>').replace('\n', '<br>')}
</body>
</html>
"""
       ^
SyntaxError: f-string expression part cannot include a backslash

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2

```

## 3. Implementação Técnica

### Passo 1: Login (Captura do Token)

Conforme a especificação da API, o login utiliza `form-data`.

```dart
Future<bool> login(String username, String password) async {
  // Nota: 10.0.2.2 é o endereço do localhost para o emulador Android
  final url = Uri.parse('http://10.0.2.2:8000/auth/login'); 

  final response = await http.post(
    url,
    body: {
      'username': username,
      'password': password,
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    String token = data['access_token']; 
    await _saveToken(token);
    return true;
  }
  return false;
}

```

### Passo 2: Persistência do Token

O token deve ser recuperado sempre que o app for reiniciado ou uma nova requisição for feita.

```dart
Future<void> _saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

```

### Passo 3: Requisições Autorizadas (Header Bearer)

Para acessar rotas como `/products/` ou `/pedidos/`, envie o token no formato `Bearer`.

```dart
Future<void> getProtectedData() async {
  final token = await _getToken();
  final url = Uri.parse('http://10.0.2.2:8000/pedidos/');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', 
    },
  );
  // ... processar resposta
}

```

## 4. Códigos de Status da API

* **401 Unauthorized**: Token inválido ou expirado. Recomenda-se redirecionar para o login.
* **400 Bad Request**: Erro na validação dos dados enviados.
* **404 Not Found**: Recurso (produto ou pedido) não encontrado.

## 5. Recomendações de Segurança

* Utilize HTTPS em produção para proteger o tráfego do token.
* Considere o uso de `flutter_secure_storage` para uma segurança mais robusta no armazenamento local do token.
"""

# Criando o arquivo .md

file_name = 'skill_auth_flutter_fastapi.md'
with open(file_name, 'w', encoding='utf-8') as f:
f.write(skill_md_content)

```
```python?code_reference&code_event_index=3
# Conteúdo do arquivo Markdown atualizado com Nome e Descrição
md_content = """# Nome: Integração de Autenticação Bearer Token no Flutter
# Descrição: Skill técnica detalhando o workflow para capturar, armazenar e utilizar tokens JWT da API FastAPI no front-end Flutter, garantindo segurança e persistência de sessão.

---

## 1. Visão Geral do Workflow

O processo de autenticação segue o fluxo padrão de **OAuth2 Password Flow**:
1.  **Autenticação**: O app envia credenciais para `/auth/login`.
2.  **Armazenamento**: O token recebido é salvo localmente no dispositivo.
3.  **Autorização**: O token é anexado ao cabeçalho `Authorization` em todas as requisições protegidas.

## 2. Requisitos (pubspec.yaml)

Para implementar este workflow, são necessárias as seguintes dependências:
- `http`: Para realizar as chamadas à API.
- `shared_preferences`: Para persistir o token no armazenamento local.

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2

```

## 3. Implementação do Workflow

### Passo 1: Realizar Login e Capturar o Token

A API espera um corpo do tipo `form-data` com os campos `username` e `password`.

```dart
Future<bool> login(String username, String password) async {
  final url = Uri.parse('http://10.0.2.2:8000/auth/login'); // URL para emulador Android

  final response = await http.post(
    url,
    body: {
      'username': username,
      'password': password,
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    String token = data['access_token']; // Extrai o token do JSON de resposta
    await _saveToken(token);
    return true;
  }
  return false;
}

```

### Passo 2: Persistência Local

O token deve ser armazenado para que o usuário permaneça logado após fechar o app.

```dart
Future<void> _saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

```

### Passo 3: Utilizar o Token em Requisições (Header Bearer)

Para acessar endpoints protegidos (como `/products/` ou `/pedidos/`), o cabeçalho `Authorization` é obrigatório.

**Formato do Header:** `Authorization: Bearer <seu_token>`.

```dart
Future<void> fetchOrders() async {
  final token = await _getToken();
  final url = Uri.parse('http://10.0.2.2:8000/pedidos/');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Anexando o token conforme a API exige
    },
  );

  if (response.statusCode == 200) {
    // Processar dados do histórico de pedidos
  }
}

```

## 4. Tratamento de Erros e Expiração

A API retorna códigos de erro específicos que o Flutter deve tratar:

* **401 Unauthorized**: O token expirou ou é inválido. O app deve redirecionar para a tela de login.
* **404 Not Found**: Recurso não encontrado.
* **400 Bad Request**: Erro de validação de dados.

## 5. Dicas de Segurança

* Nunca armazene a senha do usuário em texto puro no `SharedPreferences`.
* Utilize `flutter_secure_storage` se precisar de uma camada extra de criptografia no armazenamento do token.
* Sempre utilize HTTPS em produção para evitar interceptação do token (Man-in-the-middle).
"""

with open('skill_token_flutter_v2.md', 'w', encoding='utf-8') as f:
f.write(md_content)

```
Aqui está a sua skill em formato `.md` com o nome e a descrição incluídos no início, detalhando o workflow de integração do token da sua API no Flutter:

O arquivo contém:
* **Nome e Descrição**: Identificação clara da finalidade da skill no início do documento.
* **Workflow de Autenticação**: Passos para envio de credenciais via `form-data`, armazenamento local e autorização.
* **Exemplos de Código**: Implementações para login, salvamento de token com `shared_preferences` e uso do cabeçalho `Authorization: Bearer`.
* **Tratamento de Erros**: Gestão de códigos HTTP (401, 404, 400) conforme especificado na sua API.

Sua skill em formato Markdown está pronta:

[file-tag: code-generated-file-0-1778469496675900790]

```
