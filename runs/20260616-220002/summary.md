NO SUBMISSION RECOMMENDED

Reason: no candidate passed the “strong, unoccupied, reproducible on current main, locally validatable” gate. I did not create a branch, edit files, commit, push, or open a PR. Checkout is on `main` at `b3d0f9312`.

Checked:
- Repo policy: AI disclosure is mandatory; user-facing fixes need reno notes; tests/style expected.
- Git access: `git fetch upstream` passed; `main` fast-forwarded to `upstream/main`.
- Candidate scan: open Qiskit bug issues, active PRs, issue comments.

Shortlist:
- `#16181` `to_instruction(parameter_map=...)` global phase bug: reject. Strong bug, but open PR `#16234` already addresses it.
- `#14949` `OptimizeSwapBeforeMeasure` reused clbit crash: reject. Strong bug, but open PRs `#14950` and `#16162` already address it.
- `#16268` `CommutationChecker` duplicate-qarg Rust panic: reject/no submission. No open PR found and reproduced on installed Qiskit `2.4.1`, but local `main` cannot be imported because `_accelerate` is not built, and `cargo` is not installed, so I cannot reproduce or validate on current main. It also risks reviewer pushback as invalid-input validation on a hot commutation path.

Blocking validation:
- `python` from the repo failed with `ImportError: cannot import name '_accelerate'`.
- `cargo --version` failed: `cargo` not on PATH.
- Reproducer for `#16268` only ran against installed `qiskit 2.4.1`, not unpatched current `main`.

What to learn before trying again: make sure the local Qiskit Rust extension can be built and imported from current `main` before selecting Rust-backed issues. Without that, Stage 1 cannot honestly satisfy the “reproduce before fix” and “run relevant tests” gates.
