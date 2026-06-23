The file `merged-patterns.md` is being blocked as a sensitive path by the permission system. The updated content is staged at `C:\Users\Tilock\.claude\projects\C--Users-Tilock--claude-agents-qiskit-contrib\memory\merged-patterns-draft.md`. To apply it, please run this in PowerShell:

```powershell
Copy-Item "C:\Users\Tilock\.claude\projects\C--Users-Tilock--claude-agents-qiskit-contrib\memory\merged-patterns-draft.md" "C:\Users\Tilock\.claude\agents\qiskit-contrib\merged-patterns.md"
```

---

Here is a summary of every change made and the evidence behind it:

**What changed in `merged-patterns.md`** (based on PRs #16394, #16323, #16249, #16175, #16080, and #817):

1. **Merge profile** ΓÇö added two new hard requirements confirmed from real review threads: (a) the LLM disclosure checkboxes in the PR body are mandatory (alexanderivrii blocked #16323 until filled in), and (b) never merge `main` up into the branch (jakelishman said so unprompted on #16249 and #16175).

2. **Fertile areas** ΓÇö expanded to include: **circuit library arithmetic** (#16394 MultiplierGate, #16080 adder diagrams); **converters** (#16323 `dagdependency_to_circuit`); **Rust-side u64 panic fixes** (#16249 `saturating_sub`). Also corrected the qiskit-addon-cutting ruling: TSS99's clean #817 merged in June 2026 after the [codex]-branded attempts failed ΓÇö the repo is open but only for unambiguous, cleanly titled fixes.

3. **Docs exception documented** ΓÇö #16080 (TSS99, documentation-only) merged because it fixed an *objectively wrong diagram*, not added prose. The rule is now explicit: fix a wrong fact, not add more words.

4. **Avoid** ΓÇö added QASM3 (#16062, #16126 closed) and confirmed visualization stays off-limits (#16125, #16060, #16039 closed).

5. **Maintainer section** ΓÇö added **Cryoris** as an active community PR reviewer (appears in #16175, #16249, #16374). Updated alexanderivrii and jakelishman notes with direct evidence.

6. **Survival moves** ΓÇö `black --check` before every push is now the top bullet (caused delays in #16175 and #16323), and the release note is called out as something to include from the start.

