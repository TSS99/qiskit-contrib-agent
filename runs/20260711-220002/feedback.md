Based on the PR data gathered, I found two new signals from PR 16127 (jakelishman's closure comment, 2026-05-04) that are not covered by existing lessons:

- [FEEDBACK]: Do not target issues labeled "good first issue" as pipeline candidates; jakelishman stated on PR 16127 that these are reserved for humans learning the contribution process ΓÇö "it would be trivial and faster for an already onboarded Qiskit maintainer to fix them themselves" ΓÇö so an LLM targeting them adds no value and wastes maintainer review time.
- [FEEDBACK]: Scale PR body length to match the change size; jakelishman objected on PR 16127 that "tiny documentation-only changes do not need 300-line summaries" and "one-line bugfixes need one clear bug reproducer, not 300 lines of 'root cause analysis'" ΓÇö write less when the change is small.

