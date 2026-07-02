DECISION: SUBMIT

No PR was pushed or opened. Local commit is ready for Stage 2.

Branch: `fix-tautological-oracle-synthesis`  
Commit: `52fd716d0 Fix tautological boolean oracle synthesis`  
Proposed PR title: `Fix tautological boolean oracle synthesis`

Files changed:
- `qiskit/synthesis/boolean/boolean_expression_synth.py` - implementation
- `test/python/circuit/library/test_phase_and_bitflip_oracles.py` - regression tests
- `releasenotes/notes/fix-tautological-boolean-oracles-68d5f80f9bdff3cb.yaml` - release note

Candidate chosen: Qiskit/qiskit#16524. It is open, unassigned, no active PR found, reproduces on current `upstream/main`, and has clear expected behavior from the oracle definition.

Rejected shortlist:
- #16520: likely real, but performance-oriented with large QPY reproducer and unclear small fix.
- #16269: real invalid-input panic, but fuzzing-adjacent and explicitly low priority from maintainer comments.

Proposed PR body:

```markdown
## Summary

Fixes #16524.

Boolean oracle synthesis now handles expressions that are true for every assignment, such as `x | ~x`.

## Details

The ESOP synthesizer represents this case as a clause with no controls. Phase oracles emit that as a global phase of `pi`; bit-flip oracles emit it as an unconditional flip of the output qubit.

## Tests

- `python -m unittest test.python.circuit.library.test_phase_and_bitflip_oracles.TestPhaseOracleAndGate test.python.circuit.library.test_phase_and_bitflip_oracles.TestBitFlipOracleGate`
- `python -m unittest test.python.circuit.library.test_phase_and_bitflip_oracles`
- `python -m unittest test.python.synthesis.test_boolean`
- `python -m ruff check qiskit/synthesis/boolean/boolean_expression_synth.py test/python/circuit/library/test_phase_and_bitflip_oracles.py`
- `python -m black --check qiskit/synthesis/boolean/boolean_expression_synth.py test/python/circuit/library/test_phase_and_bitflip_oracles.py`
- `python -m reno.main lint releasenotes/notes/fix-tautological-boolean-oracles-68d5f80f9bdff3cb.yaml`

## AI/LLM disclosure

- [ ] I didn't use LLM tooling, or only used it privately.
- [ ] I used the following tool to help write this PR description: OpenAI GPT-5 Codex
- [x] I used the following tool to generate or modify code: OpenAI GPT-5 Codex
```

Validation:
Command: regression test before implementation fix  
Purpose: prove the added tests fail on unpatched current main  
Result: failed as expected  
Notes: 2 errors, both `ValueError: not enough values to unpack` for tautological phase and bit-flip oracle synthesis.

Command: `python -m unittest test.python.circuit.library.test_phase_and_bitflip_oracles.TestPhaseOracleAndGate test.python.circuit.library.test_phase_and_bitflip_oracles.TestBitFlipOracleGate`  
Purpose: targeted oracle regression coverage  
Result: passed  
Notes: 24 tests OK.

Command: original #16524 transpile reproducer  
Purpose: confirm reported failure is fixed  
Result: passed  
Notes: output `OrderedDict()` and global phase `3.141592653589793`.

Command: `python -m unittest test.python.circuit.library.test_phase_and_bitflip_oracles`  
Purpose: nearby full test file  
Result: passed  
Notes: 24 tests OK.

Command: `python -m unittest test.python.synthesis.test_boolean`  
Purpose: nearby BooleanExpression tests  
Result: passed  
Notes: 25 tests OK.

Command: ruff, black, reno lint, `git diff --cached --check`  
Purpose: style, formatting, release note, whitespace audit  
Result: passed  
Notes: full suite not run.

Human explanation pack:
- Issue: all-true boolean expressions synthesize to an ESOP clause with no controls, and the old code could not unpack that clause.
- Expected behavior: a phase oracle for `f(x)=1` is `-I`, i.e. global phase `pi`; a bit-flip oracle for `f(x)=1` flips the output qubit unconditionally.
- Root cause: the synthesizer assumed every ESOP clause had at least one non-`-` variable. A tautology is represented as an all-`-` clause, so `zip(*[])` produced nothing to unpack.
- Fix: handle the empty-control clause directly. Phase synthesis adds `pi` to `global_phase`; bit synthesis applies `x` to the output qubit.
- Test: existing public statevector tests now include a tautological expression. They fail before the fix and pass after it.
- Maintainer questions: “Why touch bit-flip too?” Same ESOP edge case, same public oracle semantics, adjacent code path. “Why global phase?” Because `(-1)^1 = e^{i*pi}` for every basis state. “Why not simplify the boolean expression earlier?” The ESOP already encodes the case; the synthesizer just needed to emit the zero-control operation.
