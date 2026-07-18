Based on the PR data, I have two clear new signals grounded in explicit maintainer statements.

- [FEEDBACK]: Never remove the LLM disclosure section from the PR template body; Cryoris flagged its absence on PRs 16151, 16201, and 16215, explicitly saying TSS99 "keeps overwriting" the template ΓÇö if LLMs were genuinely not used, tick the "I did not use LLMs" option, but the section must always remain in place.
- [FEEDBACK]: Include a regression test that reproduces the bug using the exact API form shown in the issue report; gadial asked on PR 16201 for a test using the builder `with qc.for_loop():` form to match the issue's own reproduction, noting "practice is sometimes tricky" even when equivalent code paths should theoretically behave identically.

