NO SUBMISSION RECOMMENDED

**Reason:** the required technical gate failed before issue selection. `cargo` is not on `PATH`, and the repo-local Qiskit import fails because `_accelerate` is not built. Your rules explicitly say not to select or fix issues unless current `main` can build/import locally.

**What was checked:**
- Read Qiskit contribution policy, PR template, issue template, release-note guidance, and testing guidance.
- Confirmed AI use is allowed only with disclosure in the PR description.
- Ran `git fetch upstream`: passed; `upstream/main` is now `252ad7b8d4541ea71e6016e61e10f6642d74d23a`.
- Ran `cargo --version`: failed, `cargo` not recognized.
- Ran `python -c "import qiskit, qiskit._accelerate"`: failed, `_accelerate` cannot be imported from this checkout.
- Checked for built extension files: none found.
- Checked worktree: no file changes, no branch created, no commit created.

**Blocked submission:** cannot honestly reproduce or validate bugs on current Qiskit `main` without Rust/Cargo and a built `_accelerate` extension. The installed PyPI package is Qiskit `2.4.1`, but that is not a substitute for validating against current main.

**Before trying again:**
Install Rust/Cargo and required Windows build tools, then from the repo run something like:

```powershell
python setup.py build_rust --inplace
python -c "import qiskit._accelerate"
```

Only after that passes should Stage 1 search issues or prepare a patch.
