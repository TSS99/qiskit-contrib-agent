NO SUBMISSION RECOMMENDED

Reason: the mandatory pre-selection environment gate failed. `git fetch upstream` succeeded, but `cargo` is not on `PATH`, and `python -c "import qiskit._accelerate"` fails because the Rust extension is not built/importable from this checkout. Per your rules, I stopped before issue search, branch creation, edits, or commit.

What I checked:
- [CONTRIBUTING.md](</abs/path/D:/CDAC Projects/Qiskit_Advocate/qiskit/CONTRIBUTING.md>) including setup, AI policy, release notes, tests, lint.
- [PULL_REQUEST_TEMPLATE.md](</abs/path/D:/CDAC Projects/Qiskit_Advocate/qiskit/.github/PULL_REQUEST_TEMPLATE.md>)
- Bug/feature issue templates.
- [releasenotes/config.yaml](</abs/path/D:/CDAC Projects/Qiskit_Advocate/qiskit/releasenotes/config.yaml>)
- [qiskit_bot.yaml](</abs/path/D:/CDAC Projects/Qiskit_Advocate/qiskit/qiskit_bot.yaml>)

Key policy constraints:
- AI-assisted contributions must disclose tool name/version in the PR description.
- User-facing bug fixes need a reno release note.
- PR titles should be concise and explanatory.
- Tests/style should pass locally where applicable.
- Use `Fix #...` if addressing an issue.
- Changelog category is controlled by PR labels such as `Changelog: Fixed`.

Commands run:
- `git fetch upstream` passed.
- `cargo --version` failed: `cargo` not recognized.
- `python -c "import qiskit._accelerate; print(qiskit._accelerate.__file__)"` failed with `ImportError`.
- `git status --short --branch`: still on `main`, clean worktree, `main...origin/main [ahead 203]`.

Before trying again, fix the local build environment: install Rust/Cargo, ensure Windows C++ build tools are available, activate the intended dev venv, install build/test deps, run `python setup.py build_rust --inplace`, and verify `python -c "import qiskit._accelerate"` succeeds from current `upstream/main`.
