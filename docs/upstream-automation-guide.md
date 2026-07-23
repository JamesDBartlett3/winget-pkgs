# Direct Upstream Automation Status

Direct upstream PR creation is intentionally disabled for now.

## Why

The previous direct-upstream workflow mixed together several unstable pieces:

- scheduled execution that depended on the wrong branch model
- authenticated cross-repository pushes
- PR creation directly against `microsoft/winget-pkgs`
- manifest generation that was weaker than the current Bitwig manifests
- validation that only checked whether files existed

Until the fork automation is stable, the repository keeps a single supported workflow:

- **`.github/workflows/bitwig-auto-update.yml`**
- It creates a **review PR in your fork only**
- It runs **real manifest validation** before that PR is opened

## Recommended flow

1. Let the fork workflow generate and validate the Bitwig manifest folder.
2. Review the PR in your fork.
3. Create a clean contribution branch from upstream.
4. Copy only `manifests/b/bitwig/bitwig/<version>/` into that branch.
5. Open the upstream PR manually.

## Bringing direct upstream automation back later

If you want to revisit direct upstream submission later, do it after the fork flow has proven reliable. At that point, add it back as a separate workflow with all of the following in place:

- a clear default-branch strategy for scheduled runs
- PAT-backed authentication for pushes and PR creation
- explicit workflow permissions
- the same manifest-generation path used by the fork workflow
- the same `winget validate` step used by the fork workflow

For now, the supported automation path is: **generate in fork, review in fork, submit upstream manually**.
