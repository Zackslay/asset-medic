# Asset Medic 0.1.0 — public beta

Find where that Roblox asset is hiding. Replace it safely.

Paste an asset ID, Roblox asset URL, or Output error into a local Studio panel. Find matching objects and readable script lines, review replacements, and apply selected property changes as one undo operation.

## Downloads and installation

- `AssetMedic-0.1.0.rbxmx`: the plugin.
- `AssetMedic-TestPlace.rbxlx`: a disposable integration-test place, not the plugin.
- `AssetMedic-0.1.0-source.zip`: source, tests, documentation, and build configuration.
- `SHA256SUMS.txt`: checksums for these files.

In a blank Studio place, use Explorer's **Insert from File** to insert the plugin file. Right-click the root AssetMedic Script and choose **Save / Export → Save as Local Plugin**. Leave the root Script enabled when saving the plugin. Remove the inserted Script from the place afterward, then open a fresh Studio instance and use **Plugins → Asset Medic**.

## Verified

23 automated core tests, both Rojo builds, exact-source artifact verification, 15 writable Studio property cases, current script text, batch Undo/Redo, and installed-plugin texture replacement with Edit → Undo. UI regression checks cover readable long previews at 360 × 500 and pagination scroll behavior. See `docs/VALIDATION.md` for evidence and limits.

## Beta limits

- Test replacements on a saved copy of your place first.
- No asset permission, moderation, type, or availability diagnosis.
- Scripts and MeshPart geometry are read-only.
- Light-theme visual review, broader display scaling, plugin-manager unload, and all interactive error states still need coverage.
- Strict static type analysis has not been performed. CI status must be checked on the public repository.
- The Creator Store listing is not published.

## Feedback

Open a GitHub issue with your Studio version, reproduction steps, expected and actual behavior, and relevant Output messages. Remove private source and asset details before sharing. Useful contributions include property coverage, parsing examples, and reproducible replacement or undo bugs.
