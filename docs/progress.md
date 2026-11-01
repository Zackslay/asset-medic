# Asset Medic implementation ledger

Spec: approved plan in this chat, 2026-11-01.

- Pre-flight: ID parser feeds scanner; scanner results feed preview and replacement; UI owns cancellation and selection. Inventory uses property results only to avoid treating arbitrary script numbers as assets.
- Ruling: use a new standalone directory on the existing non-main branch. The parent repository contains unrelated changes; do not change its branch, index, or worktree.
- Ruling: MeshPart.MeshId is searchable but read-only. Roblox protects this property; replacing the instance or fetching geometry would add side effects outside safe property replacement.
- Validation: local Luau tests use luau-web and explicit instance/history adapters. These are not live Studio evidence.
- Live Studio: currently connected to an unrelated Factory Tycoon place; do not insert fixtures or plugin sources there.
- Task 1 complete: core scanner/parser/replacement/controller suite passed 20/20; plugin and fixture Rojo builds passed.
- Engine checks: detached Instances validated 15 writable definition pairs; actual UI API construction/rendering passed. Detached 5000-sound scan returned 5000 results in 0.416s with 25 yields. History was an adapter, not proof of Studio undo.
- Final review: fresh reviewer found cancellation during long script scans and missing plain sound-permission error parsing. Both reproduced with failing tests before the fix pass.
- Final: minor (deferred): preview can truncate long object paths or original URLs; IDs in ordinary rbxassetid form remain visible. Expandable details can follow.
- Final: minor (deferred): page changes retain scrolling offset. Users can scroll to the top; no data is omitted.
- Final: fixed cancellation and contextual permission-error extraction; both tests observed RED, then full suite GREEN at 23/23.
- Studio: opened generated fixture in a separate instance. Command Bar spec passed actual property writes, editor source, replacement, undo/redo and UI construction; 5000-sound scan took 0.425s/25 yields. MCP execution refuses recording because MCP already wraps commands; use the Command Bar for this test.
- UI: current production entry point started in a temporary Plugin context. Visible Find/Code/Preview/Apply workflow succeeded on 3 property references and 1 script reference; engine assertions verified property changes and unchanged source.
- Remaining checks and minor limitations are recorded in VALIDATION.md. No public repository or Creator Store listing was created or published.
