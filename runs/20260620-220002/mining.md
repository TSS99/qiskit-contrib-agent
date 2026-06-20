The `.claude/agents/` path is triggering a sensitive-file permission gate on all write tools. The user needs to approve the edit. Here is the complete replacement content so you can review it and approve when prompted ΓÇö or paste it yourself:

---

**What changed and evidence used:**

The file was rewritten based on: `gh pr list` on Qiskit/qiskit (60 merged, filtered to ~12 genuine community PRs), `gh pr view` review threads for #16394, #16323, #16175, #16249, and #16080, plus `gh search prs --author TSS99` for the full TSS99 history.

Key updates vs. the old file:

1. **TSS99 merged PR list corrected**: #16080 (DraperQFTAdder diagram fix) is state=MERGED ΓÇö it was missing. The old "docs always close" claim is false.

2. **Merge profile tightened**: Typical impl change is now 1-2 lines (+15 to ~35 total); the old "~90 lines" overstated. Added the PR template requirement (alexanderivrii blocks on missing LLM disclosure or release note, as seen in #16323).

3. **Fertile areas expanded**: Circuit library arithmetic (#16394 MultiplierGate), DAG converters (#16323), `pi_check`/circuit tools (#16175), Rust underflow fixes (#16249) ΓÇö all newly merged since the last mining run.

4. **Docs avoid clause softened** with explicit exception: "fix wrong content" (verifiable mismatch + linked issue) merges; "clarify/expand correct content" does not. PR #16080 is the proof.

5. **Cryoris added** as a named reviewer: he is the de facto approver for circuit library and arithmetic PRs, responds quickly to clean fixes, defers refactors to follow-up issues.

6. **alexanderivrii profile updated**: now lists his three explicit gate criteria (LLM template, release note, black formatting) with #16323 as the evidence.

7. **jakelishman updated**: confirmed still approves small community fixes (#16249, "Thanks!") but flags unnecessary `main` merges.

8. **Recovery moves expanded**: `black` lint and PR template completeness added as the two most common first-response blockers.

9. **qiskit-addon-cutting**: TSS99's #817 (no `[codex]` tag) is open but has zero reviews ΓÇö still garrison-dominated, still avoid.

