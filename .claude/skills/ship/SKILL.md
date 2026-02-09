# Ship to Production
1. Verify current branch is NOT master: `git branch --show-current`
2. Run all tests: `npm test`
3. If tests pass, merge current branch into master
4. Push master to origin
5. Clean up the worktree: `git worktree remove <path>`
6. Delete the local and remote feature branch
7. Confirm deployment status
NEVER skip the branch check in step 1.
