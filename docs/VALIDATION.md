# Validation — 2026-11-01

## Local checks

- Core Luau suite: 23 tests passed, covering ID parsing/precision/boundaries, contextual permission errors, scripts, inventory, overlapping scopes, inaccessible scripts, cancellation, protected geometry, replacement previews, stale/deleted targets, recording refusal, play mode, write failures, and controller lifecycle.
- All shipped source files and the Studio fixture spec compiled through luau-web. This is syntax compilation, not strict static type analysis.
- Rojo 7.7.0 built both the versioned plugin and disposable fixture place.
- Artifact verification compares the actual `.rbxmx` root Script and child modules against current source files.
- A fresh reviewer inspected parser, scanner, replacement, UI, and packaging. Two important findings were reproduced with failing tests and fixed: long-script cancellation and contextual sound-asset errors.

## Actual Studio checks

Studio version: **0.745.0.7451137**. Tests ran in a separately opened local `AssetMedic-TestPlace.rbxlx`, not the existing Factory Tycoon place.

- The generated Studio integration spec ran from the Command Bar and passed supported property writes, current editor source, replacement, actual ChangeHistoryService undo/redo, and UI result/preview construction.
- A scan of 5,000 fixture sounds returned 5,000 results in approximately **0.425 seconds**, with **25 yield points**, on this machine. This is a synthetic local fixture, not a production-place or low-end-device benchmark.
- The actual plugin entry point started in a temporary Plugin context with the current production modules. No persistent installation or Creator Store publication was performed.
- In the visible docked panel, pasted `123` and clicked Find: **4 references / 5 inspected objects / 0 warnings** from the selected demo folder.
- Clicked Code: opened the matching ModuleScript at line 2.
- Entered `456`, previewed 3 writable property changes, and applied through the visible plugin button: **3 applied / 0 skipped / 0 failed**. Engine assertions confirmed SoundId, AnimationId, and Image changed, while script source retained `123`.
- Dark theme and docked layout were visually inspected at **614 × 798** panel size.
- The generated spec's temporary fixture cleaned up successfully. Expected unavailable-asset errors were emitted by Roblox while testing synthetic IDs; no asset availability or permission diagnosis is claimed.

## Follow-up verification — installed plugin and current source

- Corrected the first local installation: it had a disabled root Script and stale fixture modules. Replaced it with the built artifact and verified matching SHA-256 hashes. Asset Medic subsequently opened as an installed local plugin in a fresh Place4.
- Installed-plugin acceptance test in Place4: previewed exactly one Texture.Texture change, applied `6372755229` → `6372755230`, verified the actual property, used Studio's Edit → Undo, and verified restoration to `6372755229`. The Factory Tycoon place was not modified.
- Re-ran all 23 automated tests, both Rojo builds, and exact-source artifact verification successfully.
- Loaded current source into a temporary harness in Place4 and ran the integration spec through the native Command Bar. All 15 supported writable property cases, current editor source, script preservation, batch replacement, actual Undo/Redo, and UI construction passed. A 5,000-sound scan took **0.898 seconds** with **25 yield points** on this machine.
- Live Studio cancellation check used a 100,001-line source string with the actual scanner modules: cancellation stopped at the first yield, returned no partial references, and completed in approximately **0.016 seconds**. This checks engine execution, not a human clicking Cancel during a scan.
- A deferred MCP invocation of the integration spec failed its Undo assertion; the native Command Bar invocation passed. Deferred MCP execution is therefore not an accepted way to validate history behavior. Use the documented Command Bar route.
- Expected synthetic-asset load errors occurred during the fixture run. These do not indicate whether real assets have permission to load.

## Remaining release gates

UI polish follow-up: real Studio regression tests reproduced clipped preview values and retained page scroll before the fix. After the fix, long paths and URLs fit in automatically sized preview rows at 360 × 500, changing pages resets scroll, and same-page selection preserves it. Native button labels now use plain text for paging, categories, code navigation, and checks. `AssetMedicUISpec` is included in the disposable test place for repeatable regression checks.

- Explicit toolbar close/reopen checks and unload through Studio's plugin manager. Persistent local installation and fresh-place startup are now verified.
- Light theme, floating layout, minimum panel dimensions, and wider operating-system text scaling.
- Full visual testing of all error states and category filters.
- Human-facing Cancel button interaction during a long scan; live module cancellation at the next checkpoint is now verified.
- Strict static type analysis against Roblox definitions and CI execution on GitHub.
- Studio keyboard Undo routing while a plugin or editor has focus. The integration spec verified the actual history API's undo/redo; a Ctrl+Z UI attempt while the plugin was focused did not restore the demo properties. Use Studio's place-history Undo action, with focus on the place viewport, rather than assuming a text field forwards the shortcut.

## Resolved minor review findings

- Preview paths and values now wrap in automatically sized rows.
- Page changes now reset scroll; same-page selection preserves it.

The Creator Store listing and demo storyboard in RELEASE.md remain drafts. GitHub beta packaging is separate from Creator Store publication.
