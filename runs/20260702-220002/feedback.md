I now have enough signal to write the lessons. Here is the full output:

- [FEEDBACK]: Cap simultaneous open PRs to 1-2 at a time; jakelishman bulk-closed ~5 PRs on 2026-05-04 citing "too much volume" and explicitly said "on balance of probability it is not worth maintainer time to make an accurate determination" for each one.
- [FEEDBACK]: Keep PR descriptions to brief-summary + detailed-comments + LLM-attribution; alexanderivrii on PR 16116 objected that "Problem", "Tests", and "Validation" subsections are unnecessary since CI and the diff already show that information.
- [FEEDBACK]: Identify which architectural layer owns the bug before fixing it; jakelishman closed PR 16062 because "the root fault is not in the exporter but in the importer" and the exporter-side fix was therefore wrong regardless of logical correctness.
- [FEEDBACK]: If a maintainer opens an alternative fix for the same issue, close your PR immediately and defer; Cryoris opened PR 16153 as "the more efficient solution" to the CS/CSdg bug, and ShellyGarion closed PR 16124 the same day as superseded.
- [FEEDBACK]: Never add overhead to the happy path to improve error messages; jakelishman on PR 16258 rejected a NaN scan on all matrices saying "it causes an extra cost to all matrices to catch a specific case that's incredibly rare"; the accepted fix attaches block context only on the error path.
- [FEEDBACK]: Visualization and test-infrastructure PRs (drawer fixes, visual test migrations) were disproportionately caught in the LLM-spam closure sweep; ShellyGarion had already warned against volume in PR 16059 before jakelishman's bulk action ΓÇö treat these categories as highest-risk for closure without review.

