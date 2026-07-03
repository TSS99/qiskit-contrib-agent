I have enough signal now. Two new lessons are grounded in actual maintainer actions since the last run:

- [FEEDBACK]: Use `if len(x) == 0:` rather than `if not x:` for container emptiness checks; Cryoris objected to the falsy form on PR 16530, noting it "can easily backfire (and did in the past) and doesn't clearly show what check is happening."
- [FEEDBACK]: Cross-reference the fixed issue number inside the release note body itself; ShellyGarion explicitly asked "could you add a reference to the closed issue?" before PR 16309 was approved, and Cryoris echoed the same expectation on PR 16530 ("we link to the issue that this fixes").

