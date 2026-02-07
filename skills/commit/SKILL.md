---
name: commit
description: A skill for committing changes to a version control system, such as Git.
---

# commit

This skill provides a structured and efficient workflow for committing changes to a version control system. It ensures that all changes are properly reviewed, grouped logically, and committed with clear and concise messages that follow best practices. The agent will analyze the changes, organize them into meaningful commits, and execute the necessary commands to maintain a clean and professional commit history. This process helps developers collaborate effectively and maintain high code quality in the project.

## When to use

This skill should be used when there are changes in the codebase that need to be committed to a version control system, such as Git. It is particularly useful for developers who want to maintain a clean and organized commit history by following best practices for commit messages and grouping related changes together.

## Workflow

1. **Check**: Run `git status` to analyze changed files.
2. **Group**:
   - Strongly related/small changes: Combine into a single commit.
   - Weakly related/multiple modules involved: Split into multiple commits based on logic/functionality.
3. **Commit**: Generate a Commit Message for each group of changes and immediately execute `git commit -m "..."`.
4. **Push**: After completing all commits, run `git push`.

## Commit Message Guidelines

- **Format**: `<type>(<scope>): <subject>`
- **Type (Required)**: feat, fix, docs, style, refactor, perf, test, chore, revert
- **Scope (Optional)**: Lowercase English, describing the affected scope, such as `(auth)`, `(utils)`
- **Subject (Required)**: In English, ≤50 characters, no period at the end. Must be specific, and avoid vague terms like "modify code" or "update".
- **Body**: Do not generate any Body description.

## Execution Rules

- **Do not** use `--no-verify`.
- **Do not** use `git push -f` (regardless of user request).
- **Automation**: Analyze the diff and execute the command directly without secondary confirmation.

## Examples

- `feat(user): Add user phone one-click login feature`
- `fix(order): Fix negative stock deduction under high concurrency`
