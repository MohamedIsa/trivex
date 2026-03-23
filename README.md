# Trivex

AI-powered trivia game with ELO rating, built with Flutter and Cloudflare Workers AI.

Trivex generates trivia questions on the fly using a large-language model running on
Cloudflare's edge network. Players pick a topic, answer timed questions, and earn an
ELO rating that rises or falls based on question difficulty. The app supports English
and Arabic, deduplicates questions across rounds, and lets players configure how many
questions they want per game.

## Features

- **AI-generated questions** — every game is unique; questions are created in real time
  by Llama 3.1 8B running on Cloudflare Workers AI
- **ELO rating system** — player skill is tracked with a persistent ELO score stored
  locally via Hive
- **Multilingual (EN / AR)** — full support for English and Arabic question generation
- **Question deduplication** — previously seen questions are excluded so rounds stay
  fresh
- **Configurable question count** — choose how many questions per game
- **Per-question AI time limit** — each question has an individually tuned time limit
  (10–30 s) set by the LLM based on difficulty

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile / Desktop | Flutter (SDK ^3.11.0, Dart ^3.11.0) |
| State management | Riverpod + riverpod_annotation / riverpod_generator |
| Code generation | freezed, build_runner, hive_generator |
| Routing | go_router |
| Hooks | flutter_hooks |
| Local storage | Hive (hive_flutter) |
| Charts | fl_chart |
| Backend | Cloudflare Workers (TypeScript, Wrangler) |
| LLM | `@cf/meta/llama-3.1-8b-instruct-fast` via Workers AI |

## Architecture

```
┌─────────────┐    POST /generate    ┌────────────────────┐
│  Flutter UI  │ ──────────────────▸ │  Cloudflare Worker  │
│  (screens/)  │ ◂────────────────── │  worker/src/index.ts│
└──────┬───────┘   JSON response     └────────┬───────────┘
       │                                      │
       ▼                                      ▼
 GameStateNotifier                      Workers AI (LLM)
 providers/game_state_notifier.dart     llama-3.1-8b-instruct-fast
       │
       ▼
 QuestionService
 services/question_service.dart
       │
       ▼
 Hive (ELO history, question cache)
```

**Request flow:** UI triggers a new game → `GameStateNotifier` calls
`QuestionService.fetchQuestions()` → HTTP POST to the Worker → Worker builds a
prompt, calls Workers AI, validates the JSON response, and returns an array of
questions → `GameStateNotifier` updates state → UI renders the game screen.

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ^3.11.0 |
| Dart SDK | ^3.11.0 (bundled with Flutter) |
| Node.js | 18+ (for Wrangler CLI) |
| npm | 9+ |
| Cloudflare account | Free tier works (10 000 neurons / day) |

## Getting Started

### Flutter app

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed, riverpod_generator, hive_generator)
dart run build_runner build --delete-conflicting-outputs

# Launch on a connected device or emulator
flutter run
```

### Worker (API backend)

```bash
cd worker

# Install dependencies
npm install

# Deploy to Cloudflare
npx wrangler deploy
```

For local development you can use `npx wrangler dev` which starts the Worker on
`http://localhost:8787`.

## Configuration

All Worker configuration lives in [`worker/wrangler.toml`](worker/wrangler.toml):

```toml
name = "trivex-worker"
main = "src/index.ts"
compatibility_date = "2024-11-01"
compatibility_flags = ["nodejs_compat"]

[ai]
binding = "AI"          # Workers AI binding — required

[vars]
LLM_MODEL = "@cf/meta/llama-3.1-8b-instruct-fast"   # model identifier
```

| Key | Purpose |
|-----|---------|
| `[ai] binding` | Binds the Workers AI service so the Worker can call `env.AI.run()` |
| `LLM_MODEL` | The model identifier passed to Workers AI. Change this to swap models. |

> **Note:** You must be logged in to Wrangler (`npx wrangler login`) and your
> Cloudflare account ID is resolved automatically from your login session. No
> manual account-ID configuration is needed.

The Flutter app points at the deployed Worker URL in
`lib/constants/api_constants.dart`. Update `kWorkerBaseUrl` if you deploy to a
different Worker name or custom domain.

## Running Tests

```bash
flutter test
```

All tests live under the `test/` directory and cover services, providers, and
models.

## Project Structure

```
trivex/
├── lib/
│   ├── main.dart              # App entry point, Hive init
│   ├── app/                   # Router (go_router)
│   ├── constants/             # API URL, timeouts
│   ├── exceptions/            # Custom exception types
│   ├── models/                # freezed data classes + Hive adapters
│   ├── providers/             # Riverpod notifiers (game state, ELO)
│   ├── repositories/          # Data-access layer
│   ├── screens/               # UI screens (home, topic, game, result, loading)
│   ├── services/              # QuestionService, EloService, BotEngine, ScoreService
│   ├── theme/                 # App theme
│   └── widgets/               # Reusable widgets
├── worker/
│   ├── src/index.ts           # Cloudflare Worker entry point
│   ├── wrangler.toml          # Worker config (AI binding, model)
│   └── package.json           # Worker dependencies
├── test/                      # Flutter unit / widget tests
└── pubspec.yaml               # Flutter dependencies
```
