# Copilot Instructions

Use Hindsight memory when available through the configured VS Code MCP server named `hindsight`.

- Before planning or implementing non-trivial changes, recall relevant project memories.
- Retain durable decisions, constraints, architectural choices, debugging outcomes, and user preferences.
- Do not retain secrets, API keys, tokens, or private credentials.
- The local Hindsight API runs at `http://localhost:8888`; the project memory bank is `pikacircle`.
- If running in GitHub cloud coding agent, localhost is not available unless the environment explicitly starts Hindsight; proceed without Hindsight and mention that memory tools were unavailable.

Project basics:

- Flutter/Dart app using Appwrite as backend.
- Prefer offline-first behavior, responsive design, accessibility, performance, and secure handling of user data.
