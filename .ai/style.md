# 🎨 Guia de Estilização - Fazenda Boa Esperança

## 📋 Sumário
1. [Paleta de Cores](#paleta-de-cores)
2. [Variáveis de Estilo](#variáveis-de-estilo)
3. [Componentes Estilizados](#componentes-estilizados)
4. [Exemplos de Uso](#exemplos-de-uso)
5. [Responsividade](#responsividade)

---

## 🎯 Paleta de Cores

### Cores Principais
| Nome | Código Hex | Uso Principal |
|------|------------|---------------|
| **Preto** | `#000000` | Fundos principais, cabeçalhos, textos em destaque |
| **Branco** | `#FFFFFF` | Fundos de cards, textos em fundos escuros |
| **Verde** | `#2E7D32` | Ações positivas, sucesso, vendas, botões principais |
| **Laranja** | `#FF6B00` | Destaques, ações secundárias, botão de retorno |

### Variações de Cores
| Cor | Código Hex | Uso |
|-----|------------|-----|
| **Verde Claro** | `#4CAF50` | Badges de sucesso, botões secundários |
| **Verde Escuro** | `#1B5E20` | Textos em fundos verdes |
| **Verde Fundo** | `#E8F5E9` | Fundos de badges verdes |
| **Laranja Claro** | `#FF9800` | Badges de aviso |
| **Laranja Escuro** | `#E65100` | Textos em fundos laranjas |
| **Laranja Fundo** | `#FFF3E0` | Fundos de badges laranjas |
| **Vermelho** | `#E74C3C` | Ações de exclusão, erros |
| **Cinza Claro** | `#F5F5F5` | Fundos de tabelas, separadores |
| **Cinza Médio** | `#E0E0E0` | Bordas, divisores |
| **Cinza Escuro** | `#9E9E9E` | Textos secundários |

---

## 📐 Componentes Estilizados

### 1. Cards

#### Card Padrão (Branco)
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[300]!),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  padding: EdgeInsets.all(16),
  child: ...,
)