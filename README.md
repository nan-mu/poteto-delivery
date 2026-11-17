# poteto-delivery

poteto-delivery 是调用已安装 PStack 的薄入口，支持 Pi、Claude Code 和 Codex，并在 T3 Code 中处理必要的线程与工作区交接。它需要显式调用。

## 职责

- **PStack**：任务分类、Playbook、Agent 编排、实现、验证和 PR 生命周期。
- **当前 Harness**：Skill 加载、原生文件与命令工具、子代理接口和权限。
- **T3 Code**：线程及工作区绑定、当前线程迁移和独立线程启动。
- **Magpie**：Skill 分发、已有模型路由基础设施及 GitHub MCP。
- **poteto-delivery**：发现 PStack、适配调用接口、传递任务上下文，并应用本次调用的 GitHub 路由约定。

实际执行规则统一维护在 [SKILL.md](SKILL.md)，不在 README 重复定义。

## 安装

1. 通过 Magpie 或当前 Harness 支持的方式安装 PStack，使 `poteto-mode` 及所需依赖出现在会话注册的 Skill 或 Plugin 资源中。
2. 将本仓库作为 `poteto-delivery` Skill 安装到当前 Harness 支持的位置，保留目录结构，包括 [agents/openai.yaml](agents/openai.yaml)。也可通过当前 Harness 支持的 Skill 分发方式安装。
3. 在 T3 中使用时，确保会话暴露原生线程和工作区工具；涉及 GitHub 操作时，确保 Magpie GitHub MCP 可用。

本仓库不包含 PStack 副本，不提供脚本、Hook 或委派运行时，也不修改上游 Skill。

## 调用

在当前 Harness 中显式调用并提供任务正文：

| Harness | 入口示例 |
| --- | --- |
| Pi | `/skill:poteto-delivery 修复订单页面的提交错误` |
| Claude Code | `/poteto-delivery 修复订单页面的提交错误` |
| Codex | `$poteto-delivery 修复订单页面的提交错误` |

Pi 和 Claude Code 使用 Skill frontmatter 的显式调用控制；Codex 使用 `agents/openai.yaml` 的 `policy.allow_implicit_invocation: false`。实际支持取决于当前 Harness 版本，不能仅凭 frontmatter 宣称三个宿主都已强制执行。

入口会按已安装 PStack 的上游适配规则加载和组合技能，再将工作流交给 PStack。缺少必要能力时会报告具体阻塞，不建立替代工作流。

## 使用说明

在 T3 中，当前线程迁移到新 Worktree 与启动独立线程是不同操作。入口先核对线程绑定，并优先复用属于当前任务的工作区。迁移通过 T3 handoff 延续原任务；独立线程仅在用户要求时启动，目的线程重新核对绑定和依赖。

本次显式调用及必要交接中，本地文件修改使用原生工具，提交和分支推送使用 git；PR、Issue、Review、评论、标签与 Reviewer 操作使用 Magpie GitHub MCP。缺少对应 MCP 能力时报告 `BLOCKED`。该约定不会安装为其他任务的全局规则。

本仓库提供接口规则和最小调用元数据，不保证某个环境已经完成集成验证。实际使用仍需检查该会话的 Skill 注册、工具 Schema、T3 绑定和 MCP 能力。
