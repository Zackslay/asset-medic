# Contributing

Keep contributions focused on locating asset references and safe, reviewable property replacement.

- Use strict Luau. Keep parsing pure, scanning read-only, and mutations in Replacement.
- Never execute scripts being scanned or automatically edit their source.
- Add regression tests for exact-ID boundaries and replacement safety. The Node harness runs the actual Luau modules, not a reimplementation.
- New property support belongs in Properties and the README table. Test read and write behavior in the disposable Studio place; mark protected properties read-only.
- Verify cancellation, plugin unloading, and Studio undo for changes that affect lifecycle or mutation.
- Run `npm ci`, `npm test`, `npm run build`, and `npm run build:fixture`.
- Report Studio version and performed manual checks. Do not present adapter tests as proof of live engine behavior.

Bug reports should include the input format, expected result, observed result, and a minimal reproducible fixture. Remove private scripts and asset IDs if needed; a small synthetic reproduction is enough.
