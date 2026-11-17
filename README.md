# poteto-delivery

poteto-delivery 是一组面向 T3 Code 代码工程流程的个人使用习惯 Skills。它记录个人的软件工程工作方式、工具使用约定、工作区管理习惯，以及与 PStack 的协作方式，通过显式调用生效。

T3 Code 是主要设计目标。Pi 是当前适配的辅助运行环境，其 Agent 能力取决于实际加载的扩展和 Agent Definition。

## 职责与边界

| 组件 | 职责 |
| --- | --- |
| T3 Code | 主要工作环境，提供线程、Worktree 和相关原生工具 |
| PStack | 实际任务分类、Playbook、Agent 编排、实现、验证和 PR 生命周期 |
| Magpie | Skill 分发、MCP 资源和现有模型路由，包括 GitHub MCP |
| poteto-delivery | 显式调用入口、必要的 Harness 接口适配、工作区绑定和上下文交接 |

poteto-delivery 不替代 PStack，也不重复实现其功能。本项目不维护任务状态机、Agent 调度器或执行引擎，不提供通用 Agent 框架或 Subagent Runtime。T3 Code 的个人使用约定只适用于本次显式调用及必要交接，不会扩展为其他项目的全局规则。

详细执行规则由 [SKILL.md](SKILL.md) 维护。

## 依赖

- 已安装的 PStack，以及会话中可解析的 `poteto-mode` 和所需依赖。
- T3 Code 当前会话暴露的线程和 Worktree 原生工具。
- 涉及 GitHub 操作时可用的 Magpie GitHub MCP。
- 在 Pi 中，实际加载的 [@tintinweb/pi-subagents](https://github.com/tintinweb/pi-subagents)，以及该运行时已注册、启用的 PStack 所需 Agent 类型。

Pi 能读取 PStack Skill，不代表 `poteto-agent` 已注册。Pi 使用现有扩展提供的 `Agent` 接口及当前 Schema，不假设 Pi 内置了子代理能力。本项目不采用 `nicobailon/pi-subagents`，也不实现或分发替代运行时。

Pi 的用户环境以 `~/.pi` 为准。默认 Agent Definition 位置为 `~/.pi/agent/agents/`，扩展设置位于 `~/.pi/agent/subagents.json`；若用户设置了 `PI_CODING_AGENT_DIR`，以其实际目录为准。Agent 注册及禁用未知类型回退是外部环境前提，本仓库不管理这些个人配置，不复制 Agent Definition，也不提供配置脚本。缺少扩展、所需类型或兼容接口时，入口报告 `BLOCKED`。

## 安装

1. 通过 Magpie 或当前环境支持的分发方式安装 PStack，使 `poteto-mode` 及所需依赖可从会话注册的 Skill 或 Plugin 资源解析。
2. 将本仓库安装为 `poteto-delivery` Skill，保留目录结构，包括 [agents/openai.yaml](agents/openai.yaml)。
3. 确认当前 T3 会话具有所需原生工具和 Magpie MCP 能力。在 Pi 中，还需确认已加载的扩展能解析并启动 PStack 请求的 Agent 类型。

本仓库不包含 PStack 副本，不修改上游 Skill，也不新增脚本、Hook 或常驻服务。

## 使用

显式调用入口并提供任务正文。以下是各环境的调用形式，不代表完整的集成验证承诺。

| 环境 | 入口示例 | 适配范围 |
| --- | --- | --- |
| T3 Code 中的 Pi | `/skill:poteto-delivery 修复订单页面的提交错误` | 当前辅助适配环境，依赖已加载的扩展、Agent Definition 和真实工具接口 |
| Claude Code | `/poteto-delivery 修复订单页面的提交错误` | 保留现有接口规则，使用前核对该会话的上游适配和所需能力 |
| Codex | `$poteto-delivery 修复订单页面的提交错误` | 保留接口规则及显式调用元数据，使用前核对当前宿主版本和工具能力 |

Pi 和 Claude Code 的显式调用控制使用 Skill frontmatter；Codex 使用 `agents/openai.yaml` 的 `policy.allow_implicit_invocation: false`。是否实际生效取决于当前宿主版本，不能仅凭这些文件宣称已强制执行。

Claude Code 和 Codex 的规则及元数据不等于端到端验证。本项目保留有用的接口适配说明，不承诺未经验证的能力，也不为多 Harness 的表面一致性引入抽象层。

入口核对 T3 线程与工作区绑定，再按已安装 PStack 的上游规则加载和组合技能，将执行交给 PStack。本地修改使用原生文件工具，提交和推送使用 git；PR 等 GitHub 操作使用 Magpie GitHub MCP。具体交接和路由规则见 [SKILL.md](SKILL.md)。
