I have all the signals I need. Here are the new lessons grounded in actual maintainer actions:

- [FEEDBACK]: Always retain and fill in the LLM disclosure section of the PR template ΓÇö Cryoris blocked merges on PRs 16201, 16215, and 16151 until the disclosure was restored; tick both code and description checkboxes if either was LLM-generated, and never remove the section even if you believe you understood the code yourself.
- [FEEDBACK]: Never add per-operation checks solely to improve error messages ΓÇö jakelishman rejected a NaN scan on every matrix in PR 16258 saying "we shouldn't be penalising the happy path to do so"; attach diagnostic context only inside the exception handler, on the error path, not on every call.

