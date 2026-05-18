---
name: commit
description: Git 提交工作流，当用户需要提交代码、生成规范提交消息、拆分多模块改动时使用。
---

# commit

执行标准化的 Git 提交流程，确保提交历史符合 Conventional Commit Messages。

## 工作流程

1. **分析更改**: 运行 `git status` 和 `git diff` 识别改动逻辑，特别留意 submodule 指针变更（参见「Submodule 规范」）。
2. **逻辑分组**: 将不同功能或模块的更改拆分为独立的提交，严禁一次性提交不相关的改动；submodule 指针更新必须独立成 commit。
3. **生成消息**: 为每组更改生成**全英文**的规范消息。
4. **自动执行**: 按顺序执行 `git add .` (或特定文件) 和 `git commit -m "<message>"`。
5. **安全推送**: 完成所有本地提交后，执行 `git push`。
6. **异常处理**: 提交失败时自动回滚暂存区，推送前需用户确认。
7. **钩子处理**: 自动识别并处理 pre-commit 钩子修改的文件。

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

## Submodule 规范

当检测到 `git status` 中存在 submodule 指针变更（`new commits` / `modified content`）时，按以下规则处理：

- **独立提交**: submodule 指针更新必须与父仓库其他改动**拆分为独立提交**，禁止混合提交。
- **Type 选择**:
  - `chore(deps)`: 例行升级、跟随上游主分支。
  - `feat(<submodule>)`: 引入 submodule 内的新功能。
  - `fix(<submodule>)`: 修复 submodule 内的 Bug。
- **Scope**: 使用 submodule 目录名（小写，去除路径前缀），如 `vendor/foo` → `foo`。
- **Subject**: 简述指针指向的变更目的，而非罗列 SHA。例如 `bump to v1.2.0` / `sync with upstream main`。
- **嵌套提交**: 若 submodule 内部有未提交改动，应先 `cd` 进入 submodule 完成提交并推送，再回到父仓库更新指针。
- **推送顺序**: 必须**先推送 submodule，再推送父仓库**，避免 CI/协作者拉取到悬空指针。

## 约束规则

- **严禁使用 Emoji**: 保持纯文本格式。
- **严禁 Force Push**: 确保远程分支安全。
- **单行模式**: 消息必须是单行，严禁换行或正文描述。
- **提交修改规则**: 远程已推送的提交禁止使用 --amend 修改。
- **文件暂存规则**: 优先按分组添加特定文件,避免使用 git add . 包含无关内容。
- **Submodule 隔离**: submodule 指针变更与父仓库代码改动严禁合并到同一提交。

## 示例

- `feat(auth): add google oauth2 support`
- `fix(db): resolve connection leak in production`
- `refactor(utils): simplify date format logic`
- `chore(deps): bump shared-ui to v2.3.1`
- `feat(theme-engine): sync with upstream main`
- `fix(protocol): update to patched release v0.9.2`
