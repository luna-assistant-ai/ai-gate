# Contributing to AI Gate

Thanks for your interest in AI Gate!

## Principles
- Small PRs, English commit messages (conventional commits)
- Tests, type-check, and lint must pass
- Respect the Code of Conduct
- DCO (Signed-off-by) required on every commit

## Quick start (monorepo)
- Clone with submodules: `git clone --recursive`
- Web (luna-proxy-web): `npm ci && npm run validate`
- API (luna-proxy-api): see the sub-repo README

## Workflow (aligned with luna-proxy-web/.claude/workflow.md)
1) Plan (todo list if 3+ steps) and validate the approach
2) Mark in_progress, implement step by step with tests
3) `npm run validate` before every commit
4) Commits: `type: short description` (feat, fix, refactor, docs, test, chore)
5) Open a PR, fill the template, link issues

## DCO (Developer Certificate of Origin)
Add a Signed-off-by line to every commit:

```
Signed-off-by: Full Name <email@example.com>
```

Configure git to sign automatically:

```
git config --global user.name "Full Name"
git config --global user.email "email@example.com"
git commit -s -m "feat: add X"
```

## Tests and validation
- Web: `cd luna-proxy-web && npm run validate`
- API: see the sub-repo

## Reporting bugs and requests
- Bugs: Issues (Bug template)
- Features: Issues (Feature template)
- Questions: Discussions or Question template
- Security: see SECURITY.md (do not open a public issue)

## Communication
- Direct and concise
- Ask questions if uncertain
- Respect the Code of Conduct

## Contact
- Support: support@ai-gate.dev
