I have enough signal. Here are the new findings:

**PR 16003**: alexanderivrii closed it saying "The underlying issue is closed, so we do not need this PR" ΓÇö the issue TSS99 was fixing had already been resolved before the PR was opened.

**PR 16080**: alexanderivrii flagged two files with "you shouldn't change this file" / "or this file" ΓÇö the paths were `.github/workflows/docs.yml` and `.github/workflows/docs_deploy.yml`, which TSS99 modified unnecessarily in a documentation-only PR.

No new signal from PR 16162 or PR 817 (bot-only comments so far). PR 16258 is stalled awaiting re-review after TSS99's June 7 ping; the existing NaN and happy-path lessons cover that thread.

---

- [FEEDBACK]: Verify the target issue is still open and unresolved on main before writing any code ΓÇö alexanderivrii closed PR 16003 immediately with "The underlying issue is closed, so we do not need this PR"; opening a fix for an already-resolved issue wastes reviewer time and is closed on sight.
- [FEEDBACK]: Restrict file changes to exactly the source files the fix requires ΓÇö alexanderivrii flagged `.github/workflows/docs.yml` and `.github/workflows/docs_deploy.yml` in PR 16080 with "you shouldn't change this file" and "or this file"; never touch CI workflow or infrastructure files when the change is limited to documentation or library code.

