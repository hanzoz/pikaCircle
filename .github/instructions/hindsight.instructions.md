---
applyTo: "**"
---

# Hindsight Memory

When Hindsight MCP tools are available, use them for cross-session project memory:

- Recall memories before non-trivial design, implementation, debugging, or planning work.
- Retain durable project facts, decisions, constraints, trade-offs, and resolved bugs.
- Never retain secrets, credentials, tokens, `.env` values, or private keys.
- Use the `pikacircle` bank via `http://localhost:8888/mcp/pikacircle/`.

Cloud Copilot agents cannot reach this local Docker endpoint unless Hindsight is started inside their environment.
