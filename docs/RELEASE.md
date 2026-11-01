# Publishing guide

## Before publishing

Use [VALIDATION.md](VALIDATION.md) for completed checks and remaining release gates. Build and test instructions live in the [README](../README.md); beta release notes live in [BETA_RELEASE.md](BETA_RELEASE.md).

Package downloads and checksums with `python scripts/package-release.py` after building both artifacts. Publish the plugin and test place as release attachments; keep dependencies and generated builds out of the source repository.

## Free Creator Store listing draft

**Title:** Asset Medic — Asset Finder & Safe Replacer

**Description:** Paste a Roblox asset ID or Output error and find where it is referenced in your place. Select matching objects, open matching script lines, browse supported asset properties, and preview bulk ID replacements before applying them. Successful edits are grouped into one Studio undo operation.

Free and open source. Runs locally with no HTTP access or account. Script matches are read-only. Does not bypass asset permissions or recover unavailable assets. MeshPart geometry is searchable but not automatically replaced.

Support server: [Discord](https://discord.gg/4cxQwKtY3q).

Repository: [Zackslay/asset-medic](https://github.com/Zackslay/asset-medic). Set the Creator Store listing to free and upload the built plugin after the remaining release gates pass. The Creator Store listing is not published yet.

## Launch demo storyboard

Record actual Studio footage; do not simulate a successful workflow.

1. Show a failed asset ID in Output, then paste it into Asset Medic.
2. Find several references hidden in different folders and one script match.
3. Select an object, then open the script line.
4. Enter a replacement ID and show old/new values in the preview.
5. Apply the batch, inspect the changed properties, then undo once.

Caption: **“Find where that Roblox asset is hiding. Replace it safely.”**

Share the repository and versioned release; add the Creator Store link once published. Invite feedback through [GitHub issues](https://github.com/Zackslay/asset-medic/issues) or the support server.
