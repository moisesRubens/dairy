# PDV Dashboard - Simples e Focado

Tela principal do PDV com:
- **Seletor de PDV** (dropdown)
- **Card de Faturamento** (destaque verde)
- **Tabela de Produtos** (adicionar ao carrinho)
- **Carrinho** (remover itens, calcular total)
- **Checkout** (finalizar venda)

## Estrutura

```
lib/
├── main.dart                    # App setup
├── config/
│   └── theme.dart              # Tema simples
└── screens/
    └── pdv_dashboard_screen.dart  # Tela principal com widgets
```

## Como Usar

```bash
flutter pub get
flutter run
```

Pronto! A tela já está funcional com dados mock e cálculos em tempo real.

## Widgets na Tela

- **ProductRow**: Linha de produto com input e botão add
- **CartItemRow**: Item no carrinho com botão remover

Tudo em uma única screen, sem complexidade!
