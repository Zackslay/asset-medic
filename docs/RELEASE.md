# Release checklist and launch material

## Validation gates

- [x] Local Luau test suite and compilation pass.
- [x] Rojo builds both the plugin and disposable place.
- [x] Run studio.spec in the disposable place; record results and timing.
- [ ] Install the local plugin and exercise toolbar toggle, dock/float, close/reopen, and unload.
- [ ] Check light/dark themes and minimum 360 × 500 panel size. Long paths and error messages remain readable.
- [ ] Verify actual Explorer selection and opening a matching script line with an unsaved editor buffer.
- [ ] Test empty input, multiple IDs, no matches, denied script access, inventory, category filter, selection scope, and no selection.
- [ ] Cancel a large scan; close the panel mid-scan; ensure no late results or errors.
- [ ] Preview a batch, edit/delete a target, apply, and verify skipped rows and one-step undo/redo.
- [ ] Attempt replacement during playtesting and while another recording is active; verify no writes.
- [ ] Review the supported-property table and limitations against the shipping artifact.

## Free Creator Store listing draft

**Title:** Asset Medic — Asset Finder & Safe Replacer

**Description:** Paste a Roblox asset ID or Output error and find where it is referenced in your place. Select matching objects, open matching script lines, browse supported asset properties, and preview bulk ID replacements before applying them. Successful edits are grouped into one Studio undo operation.

Free and open source. Runs locally with no HTTP access or account. Script matches are read-only. Does not bypass asset permissions or recover unavailable assets. MeshPart geometry is searchable but not automatically replaced.

Support server: [Discord](https://discord.gg/4cxQwKtY3q).

Attach the public repository URL only after the repository exists. Set the plugin listing to free. Upload the built artifact after the validation gates pass; neither publishing step is automated by this project.

## Launch demo storyboard

Record actual Studio footage; do not simulate a successful workflow.

1. Show a failed asset ID in Output, then paste it into Asset Medic.
2. Find several references hidden in different folders and one script match.
3. Select an object, then open the script line.
4. Enter a replacement ID and show old/new values in the preview.
5. Apply the batch, inspect the changed properties, then undo once.

Caption: **“Find where that Roblox asset is hiding. Replace it safely.”**

Launch with the GitHub source, a versioned release artifact, and the free Creator Store link. Invite narrowly scoped contributions: property coverage, parsing edge cases, and reproducible safety bugs. No growth or star-count claims until there is actual usage evidence.
