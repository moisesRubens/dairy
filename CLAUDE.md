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

The app talks to a separate **FastAPI** backend. The base URL lives in one place — [lib/config/api_config.dart](lib/config/api_config.dart) (`ApiConfig.baseUrl`, default `http://127.0.0.1:8000`). Override per target with `--dart-define=API_BASE_URL=...` (e.g. `http://10.0.2.2:8000` for the Android emulator, the LAN IP for a physical device).

Auth follows **OAuth2 Password Flow**:
- `POST /auth/login` with `form-data` (`username`, `password`) → returns `{ access_token }`.
- The Bearer token is injected on every request by the Dio interceptor in [lib/core/network/dio_provider.dart](lib/core/network/dio_provider.dart). The in-memory token lives in `authTokenProvider`; `AuthController` writes it on login/logout.
- Protected endpoints (`/products/`, `/clients/`, `/admin/metrics/...`, ...) require `Authorization: Bearer <token>`.

## Architecture

The app is **feature-first + Riverpod**. Networking goes through a single Dio instance (`dioProvider`); errors are normalized to `ApiException` via `toApiException`.

### Routing — GoRouter with role-based redirect

[lib/main.dart](lib/main.dart) boots `ProviderScope` and reads `routerProvider` from [lib/router/app_router.dart](lib/router/app_router.dart). The router has three top-level routes: `/login`, the **admin shell**, and the **vendor shell** ([lib/router/shells/](lib/router/shells/)). A `redirect` gates by auth + role: unauthenticated → `/login`; admins land on `/admin/dashboard`, vendors on `/vendor/home`; cross-area access is blocked. The router refreshes when `authControllerProvider` changes.

### Feature layering

Each feature lives in `lib/features/<x>/` with:

```
domain/        # POJOs with fromJson/toJson
data/          # Repository class + Riverpod providers (Repository provider + FutureProvider.autoDispose)
application/   # controllers (Notifier / state holders)
presentation/  # screens (ConsumerWidget) — do NOT return your own Scaffold inside a shell tab
```

Features present: `auth`, `cart`, `clients`, `metrics`, `orders`, `products`, `stock_requests`. Shared building blocks live in `lib/core/` (network, formatting), `lib/shared/widgets/` (e.g. `AsyncValueWidget`, `EmptyState`), and `lib/config/`.

When adding to a feature, **follow the exact patterns of the neighboring files** — repositories wrap calls in `try/catch` → `toApiException`, expose a `FutureProvider.autoDispose`, and call `ref.invalidate(...)` after mutations.

### Conventions

- Currency is formatted with `currencyBRL(...)` from [lib/core/format/formatters.dart](lib/core/format/formatters.dart) (backed by `intl`). Do not hand-roll `replaceAll('.', ',')`.

## Design system (enforced — apply to new UI)

Captured in [.ai/extractor.md](.ai/extractor.md) and [.ai/ui-design-system.md](.ai/ui-design-system.md). The hard rules:

- **No blue.** Anywhere. The accent is **green `#2E7D32`** for revenue/success and **red `#E74C3C`** for destructive actions.
- Black `AppBar` with white text; white scaffold background; cards are either black-on-white (revenue) or white-with-thin-grey-border (tables).
- Border radii: **16** for product grid cards, **12** for revenue/input cards, **8** for tables, **4** for inline inputs.
- Section titles bold 18; labels uppercase 10–12 grey; revenue metric bold 32 white-on-black.
- Confirm-then-delete dialogs use uppercase button labels (`CANCELAR` / `EXCLUIR`).

Refer to [lib/config/theme.dart](lib/config/theme.dart) (`AppColors`, `AppSpacing`, `AppRadii`) and the cards in [lib/features/metrics/presentation/dashboard_page.dart](lib/features/metrics/presentation/dashboard_page.dart) as the reference implementation of these conventions.

## The `.ai/` directory

`.ai/*.md` files are **design briefs / specs**, not generated artifacts. They describe intent (UI rules, feature scope, auth workflow). Read them before designing a new screen, but trust the code when the two disagree — the code is the current state, the briefs are aspiration.
