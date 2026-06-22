NO SUBMISSION RECOMMENDED

Reason: the mandatory environment gate failed before issue selection. `cargo` and `rustc` are not on `PATH`, and importing the local Qiskit Rust extension fails:

- `git fetch upstream`: passed
- `cargo --version`: failed, command not found
- `rustc --version`: failed, command not found
- `python -c "import qiskit._accelerate"`: failed, `_accelerate` cannot import
- local `HEAD` is also behind `upstream/main`

What was checked:
- `CONTRIBUTING.md`
- PR template
- bug issue template
- release-note config
- `tox.ini`
- local git/remotes/status

Relevant repo constraints:
- AI-assisted contributions must disclose tool name/version in the PR description.
- User-facing bug fixes need a reno release note.
- Tests should be added for behavior changes and run through targeted `tox`/test commands.
- Lint/style is checked through `tox -elint`, black, ruff, rustfmt, clippy, and reno lint.
- PR titles should be concise and explanatory.
- Branches should start from current `upstream/main`.

Blocked submission:
- I cannot honestly reproduce or validate any Qiskit issue on current main without a working Rust build/import.
- Per your technical rule, issue selection must stop here. No branch, code change, commit, push, or PR was created.

Before trying again:
- Install Rust/rustup and the required Windows C++ build tools.
- Fast-forward local `main` to `upstream/main`.
- Run `python setup.py build_rust --inplace`.
- Confirm `python -c "import qiskit._accelerate"` succeeds from the checkout.
