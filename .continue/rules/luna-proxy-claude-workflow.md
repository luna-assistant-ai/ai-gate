---
globs: "**/*"
description: Apply this workflow to any change or task within this project to
  ensure consistency with the documented Claude process.
alwaysApply: true
---

Follow the workflow defined in luna-proxy-web/.claude/workflow.md for all tasks in this repo: plan with a todo list for tasks >= 3 steps, validate plan with user before coding, mark tasks in_progress/completed, run `npm run validate` before every commit (type-check + lint + tests), use French commit messages with the project’s template and conventional types (feat, fix, refactor, docs, test, chore), implement step-by-step with tests when relevant, and keep communication concise and ask clarifying questions when uncertain.