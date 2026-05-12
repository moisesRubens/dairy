# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter mobile app **"Fazenda Boa Esperança"** — a PDV (Ponto de Venda / point-of-sale) for a dairy/farm operation. UI, code, and docs are in **Portuguese (pt-BR)**. Currency is **R$ (Real)**.

## Commands

```bash
flutter pub get              # install deps
flutter run                  # run on the connected device/emulator
flutter analyze              # lint (uses package:flutter_lints)
flutter test                 # run all tests
flutter test test/foo_test.dart   # single test file
flutter test --name "pattern"     # tests matching a name
flutter build apk            # release Android build
```

Dart SDK constraint: `^3.11.3`.

## Backend

The app talks to a separate **FastAPI** backend. The base URL is hardcoded as `http://127.0.0.1:8000` in [lib/services/auth_service.dart](lib/services/auth_service.dart) — the Windows-desktop target. Switch to `http://10.0.2.2:8000` for the Android emulator, or the LAN IP for a physical device. There is no env/config layer yet.

Auth follows **OAuth2 Password Flow**:
- `POST /auth/login` with `form-data` (`username`, `password`) → returns `{ access_token }`.
- Token is persisted in `SharedPreferences` under the key `'access_token'`.
- Protected endpoints (`/products/`, `/pedidos/`, ...) require `Authorization: Bearer <token>`.

See [.ai/token-integration.md](.ai/token-integration.md) for the canonical workflow (note: that file is verbatim ChatGPT output and contains noise — code blocks are authoritative, surrounding prose is not).

## Architecture

### Routing — GoRouter with a stateful shell pattern

[lib/main.dart](lib/main.dart) defines two routes: `/login` and `/`. The `/` route renders `MainShell`, which is a `Scaffold` holding the persistent `AppBar`, `Drawer`, and `BottomNavigationBar`. The four tabs (Home, Pedidos, Estoque, Perfis) are kept alive via `IndexedStack` — they preserve state when switching.

Implications for new screens that should live inside the shell:
- **Do not** return your own `Scaffold` — return just the body content (typically a `SingleChildScrollView` or `Column` with `Expanded`).
- Add the page widget to `_MainShell._pages` and add a matching `BottomNavigationBarItem`.
- For overlay/detail screens that should push on top of the shell (so the OS back button works), use `context.push('/path')` and define them as top-level `GoRoute`s — not as new tabs.

Tab navigation uses local `setState` on `_currentIndex`, not GoRouter sub-routes. `.ai/ui-shell-structure.md` recommends migrating to `StatefulShellRoute`; that hasn't happened yet.

### Folders (intended layering — partially realized)

```
lib/
├── main.dart              # GoRouter + MainShell + AppDrawer
├── config/theme.dart      # minimal ThemeData (most styling is inline)
├── domain/                # POJOs with fromJson/toJson (SalePoint, Product, Order, Output)
├── services/              # HTTP clients (one class per resource)
├── controllers/           # intended: ChangeNotifier state holders (mostly empty stubs)
└── screens/               # tab pages + login
```

State management: screens currently use **local `setState`**. The folder structure (and `.ai/tech-stack-arch.md`) anticipates a `Provider` + `ChangeNotifier` migration, but `controllers/product_controller.dart`, `services/product_service.dart`, `domain/product.dart`, `domain/order.dart`, and `domain/output.dart` are **empty stub files** — wire them up before importing.

### Watch out: stack drift between docs and code

- `.ai/tech-stack-arch.md` says **Dio + Provider**. Reality: `http` package + `setState`. When the user asks for a new feature, ask which stack to follow rather than assuming the doc.
- There are **two `LoginPage` files**: [lib/login_page.dart](lib/login_page.dart) (orphan, unused) and [lib/screens/login_page.dart](lib/screens/login_page.dart) (imported by `main.dart`). Edit the one under `screens/`. The orphan can be deleted on sight.
- Currency formatting is done manually as `R$ ${v.toStringAsFixed(2).replaceAll('.', ',')}` — the `intl` package isn't a dependency yet despite the docs in `.ai/api-data-handling.md` suggesting it.

## Design system (enforced — apply to new UI)

Captured in [.ai/extractor.md](.ai/extractor.md) and [.ai/ui-design-system.md](.ai/ui-design-system.md). The hard rules:

- **No blue.** Anywhere. The accent is **green `#2E7D32`** for revenue/success and **red `#E74C3C`** for destructive actions.
- Black `AppBar` with white text; white scaffold background; cards are either black-on-white (revenue) or white-with-thin-grey-border (tables).
- Border radii: **16** for product grid cards, **12** for revenue/input cards, **8** for tables, **4** for inline inputs.
- Section titles bold 18; labels uppercase 10–12 grey; revenue metric bold 32 white-on-black.
- Confirm-then-delete dialogs use uppercase button labels (`CANCELAR` / `EXCLUIR`).

Refer to `HomePage._buildRevenueCard` and `_buildProductTable` in [lib/screens/home_page.dart](lib/screens/home_page.dart) as the reference implementation of these conventions.

## The `.ai/` directory

`.ai/*.md` files are **design briefs / specs**, not generated artifacts. They describe intent (UI rules, feature scope, auth workflow). Read them before designing a new screen, but trust the code when the two disagree — the code is the current state, the briefs are aspiration.
