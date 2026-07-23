DECISION: SUBMIT

Prepared locally only. No push and no PR opened.

Branch: `fix-stateprep-inverse-width`  
Commit: `4a738f71d Preserve StatePreparation inverse width`  
Proposed PR title: `Preserve StatePreparation width in inverse`

**Candidate Summary**
Screened 12 open/unassigned issues across circuit library, transpiler, synthesis, primitives, QASM, and quantum info. Shortlist:

- `#16430` StatePreparation inverse width: I=3 M=4 R=5 G=5 total=17/20, strong.
- `#16160` BackendSamplerV2 IQM parsing: I=4 M=3 R=2 G=2 total=11/20, maybe/reject due external-provider repro uncertainty.
- `#16540` Gridsynth QPE panic: I=4 M=5 R=3 G=4 total=16/20, blocked because fixed `rsgridsynth` crate is not released.

**Files Changed**
- `qiskit/circuit/library/data_preparation/state_preparation.py`
- `test/python/circuit/library/test_state_preparation.py`
- `releasenotes/notes/fix-stateprep-inverse-width-16430.yaml`

**Proposed PR Body**
```markdown
## Summary

Fix #16430.

Preserve the explicit integer-bitmap width when `StatePreparation.inverse()` rebuilds the inverse gate.

## Details

`StatePreparation` keeps the original integer value, but reconstructing from that value alone lets the constructor infer the minimum width. The inverse path now forwards the existing width only for integer-backed instances, leaving label and vector inputs unchanged.

## Tests

- `python -m unittest test.python.circuit.library.test_state_preparation.TestStatePreparation.test_inverse_preserves_integer_state_width -v`
- `python -m unittest test.python.circuit.library.test_state_preparation -v`
- `black --check qiskit\circuit\library\data_preparation\state_preparation.py test\python\circuit\library\test_state_preparation.py`
- `ruff check qiskit\circuit\library\data_preparation\state_preparation.py test\python\circuit\library\test_state_preparation.py`
- `python -m reno.main lint`

### AI/LLM disclosure

- [ ] I didn't use LLM tooling, or only used it privately.
- [x] I used the following tool to help write this PR description: OpenAI Codex, GPT-5
- [x] I used the following tool to generate or modify code: OpenAI Codex, GPT-5
```

**Validation**
- `python -c "from qiskit.circuit.library import StatePreparation; gate=StatePreparation(1, num_qubits=2); inv=gate.inverse(); print(gate.num_qubits, inv.num_qubits, inv.params)"`  
  Purpose: current-main reproducer. Result: confirmed bug. Notes: output was `2 1 [(1+0j)]`.

- `python -m unittest test.python.circuit.library.test_state_preparation.TestStatePreparation.test_inverse_preserves_integer_state_width -v` before fix  
  Purpose: prove added test fails on unpatched main. Result: failed as expected. Notes: inverse expected 1 qubit and append to 2 qubits raised `QiskitError`.

- Same focused test after fix: passed.
- Full `test.python.circuit.library.test_state_preparation -v`: passed, 15 tests.
- `black --check ...`: passed.
- `ruff check ...`: passed.
- `python -m reno.main lint`: passed.
- `git diff --check`: passed with only Windows LF-to-CRLF warnings.

**Human Explanation Pack**
Issue: `StatePreparation(1, num_qubits=2).inverse()` incorrectly becomes a 1-qubit gate.

Expected behavior: the inverse of a gate should act on the same number of qubits as the original gate.

Root cause: integer inputs are stored as the original integer, and `inverse()` reconstructed from that integer without forwarding the explicit width. The constructor then inferred the minimum width from the value `1`.

Fix: for integer-backed instances only, pass `self.num_qubits` into the reconstructed `StatePreparation`. Non-integer paths still pass no `num_qubits`, matching existing validation.

Test: the new test appends a 2-qubit integer `StatePreparation` and its inverse to the same 2-qubit circuit, then checks the operator is identity. This proves both width preservation and inverse behavior through public APIs.

Likely reviewer question: “Why only integer inputs?”  
Answer: `num_qubits` is only valid for integer `params`; the constructor rejects it for labels and vectors.

Known limitation: full Qiskit test suite was not run; only the targeted adjacent module and style/release-note checks were run.
