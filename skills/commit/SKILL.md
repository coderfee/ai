---
name: commit
description: Git 提交工作流
---

# commit

执行标准化的 Git 提交流程，确保提交历史符合 Conventional Commit Messages。

## 工作流程

1. **分析更改**: 运行 `git status` 和 `git diff` 识别改动逻辑。
2. **逻辑分组**: 将不同功能或模块的更改拆分为独立的提交，严禁一次性提交不相关的改动。
3. **生成消息**: 为每组更改生成**全英文**的规范消息。
4. **自动执行**: 按顺序执行 `git add .` (或特定文件) 和 `git commit -m "<message>"`。
5. **安全推送**: 完成所有本地提交后，执行 `git push`。

## 消息规范

- **语言**: 必须使用**英文 (English)**。
- **格式**: `<type>(<scope>): <subject>`
  - **Type**: 必须从以下范围选择：
    - `feat`: New feature
    - `fix`: Bug fix
    - `docs`: Documentation only changes
    - `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
    - `refactor`: A code change that neither fixes a bug nor adds a feature
    - `perf`: A code change that improves performance
    - `test`: Adding missing tests or correcting existing tests
    - `chore`: Changes to the build process or auxiliary tools and libraries
  - **Scope**: 可选，小写英文，指出改动范围（如：auth, parser, user-api）。
  - **Subject**: 
    - 使用祈使句（Imperative mood），首字母不要大写。
    - 结尾不要加句号 `.`。
    - 简洁明了，控制在 50 字符以内。

## 约束规则

- **严禁使用 Emoji**: 保持纯文本格式。
- **严禁 Force Push**: 确保远程分支安全。
- **单行模式**: 消息必须是单行，严禁换行或正文描述。

## 示例

- `feat(auth): add google oauth2 support`
- `fix(db): resolve connection leak in production`
- `refactor(utils): simplify date format logic`
