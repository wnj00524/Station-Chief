# Codex Workflow Notes

## Important
Do not rely on "uploading the GDD" to Codex as an ad-hoc document workflow. The reliable pattern is to keep project docs in the repository and reference them explicitly.

## Current Codex context behavior
- IDE extension: open files and selected text are included automatically.
- CLI: explicitly mention relevant files or paths.
- Cloud tasks: use repository files as project context.

## Recommended prompt pattern
Use `docs/vertical-slice-brief.md` as the implementation contract.
Use `docs/gdd-overview.md` and targeted topic docs as supporting context.
Keep the task scoped to one prototype milestone at a time.
