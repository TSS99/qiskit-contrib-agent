NO SUBMISSION RECOMMENDED

Reason: the required technical pre-selection gate failed. `cargo` is not on PATH, `rustup` was not found, `~/.cargo/bin/cargo.exe` does not exist, and `python -c "import qiskit._accelerate"` fails because the local Rust extension is not built/importable. Per your own rule, issue selection must stop before any candidate work.

What was checked:
- Read Qiskit contribution policy, PR template, and bug issue template.
- Ran `git fetch upstream`: passed.
- Checked Rust tooling: failed, no `cargo`.
- Checked local extension import: failed.
- Checked git state: currently on `main`; no uncommitted changes shown; local `HEAD` is `b3d0f931...`, while `upstream/main` is `cd146f56...`.

Relevant policy constraints:
- Qiskit explicitly requires AI-tool disclosure in the PR description if AI was used.
- The PR template has an `AI/LLM disclosure` section.
- Source builds require Rust; Rust tests and formatting require Cargo.
- User-facing fixes need a reno release note.
- PR titles should be concise and explanatory; linked issues should use `Fix #...`.

Blocked submission:
- No issue shortlist was created.
- No branch was created.
- No files were changed.
- No commit was made.

Before trying again, install/activate Rust tooling for this shell, rebuild Qiskit from source, and confirm:

```powershell
cargo --version
python setup.py build_rust --inplace
python -c "import qiskit._accelerate"
```
