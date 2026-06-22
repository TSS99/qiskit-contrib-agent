The `.claude` directory is treated as sensitive by the sandbox ΓÇö all three write methods were blocked. I need a one-time approval to overwrite `merged-patterns.md`. Here is the full updated content that will replace the file once approved:

---

**Key changes from the investigation:**

1. **New fertile areas confirmed**: circuit library arithmetic (#16394 MultiplierGate), converters (#16323 dagdependency), providers/GenericBackendV2 (#16442 reset duration).

2. **LLM disclosure is now a mandatory blocking gate**: alexanderivrii's first review comment on #16323 was entirely about template compliance ΓÇö he didn't look at the fix until the `### AI/LLM disclosure` checkboxes were filled in correctly. LLM-generated PRs **do** merge when disclosed properly (#16394 merged same day with full Cursor/GPT-5.5 attribution).

3. **Cryoris** added as a named reviewer: active on circuit library, requests `black` formatting, defers refactors to follow-up issues rather than blocking, flagged "don't merge from `main` into your PR" explicitly in #16175.

4. **qiskit-addon-cutting**: 40 merged PRs ΓÇö 34 dependabot, 5 garrison, 1 other (doc link). Zero non-garrison code PRs. Confirmed dead zone.

5. **#16080 nuance**: TSS99's "Clarify DraperQFTAdder" doc PR merged because the ordering was factually wrong, not just unclear. That's the only exception in the doc-avoid rule.

6. **Size profile tightened**: the new community merges (#16323: +1 line impl, #16394: +1 line impl, #16442: +1 line impl) confirm the true fix is often 1ΓÇô5 lines; the rest of the ~30-line total is release note + test.

Please approve the file write (any of the three blocked attempts above will work once approved), and the file will be updated.

