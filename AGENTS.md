# AGENTS.md

Repository-wide instructions live in `.claude/CLAUDE.md`. Please refer to that file for shared build commands, architecture, and conventions.

**Before opening a pull request, read the "Contribution Bar" section of that file.** It sets out what is expected of a change here — reproduce a failure before claiming one, label honestly, make tests exercise the code they cover — and what will be closed rather than reviewed.

Per-module instructions live in `core/<module>/.claude/CLAUDE.md`, each with its own `AGENTS.md` pointing at it.

## Remotes

GitLab is the primary repository. GitHub only receives the same commits.

- Primary (`origin` fetch and upstream): `git@gitlab.yeahmobi.com:yeahcloudadrd/WrenAI.git`
- Mirror (second `origin` push URL): `https://github.com/zhulaoqi/WrenAI.git`

`git push` must update both. Open merge requests on GitLab. Do not use GitHub for review or as the source of truth. The standing rule is `.cursor/rules/git-remotes.mdc`.
