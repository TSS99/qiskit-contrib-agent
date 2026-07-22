I found one genuinely new signal from PR 16215. All other PRs (16530 merged cleanly, 16493/16482/16162 awaiting first review, 16201/16151 covered by existing lessons) produced no new maintainer feedback.

- [FEEDBACK]: When CI shows failures in a different language layer that a concurrent PR is already fixing, revert those cross-layer changes from your PR and let the companion PR handle them; Cryoris asked on PR 16215 to remove C API changes because PR 16214 was already addressing the same compiler-related failures ΓÇö keeping them would have created a merge conflict and duplicated effort.

