---
created: 2026-11-02
updated: 2026-11-03
type: requirement
requirement_created: 2026-08-31
meego_id: "7372003123"
---

知识编译项目下的技术需求，Meego：[【知识编译】Agent Infra](https://meego.larkoffice.com/xqd1pw/story/detail/7372003123)。

## 计划与进展

| 阶段 | 时间 | 目标 | 进展 |
| --- | --- | --- | --- |
| 开发 | 11-02 至 11-08 | 完成开发 | 已整理接入方案和关键测试计划，当前待评审、待实现 |
| 联调 | 11-09 至 11-15 | 联调 | 未开始 |

## 范围

11-02 晚间已明确：从自研 Agent Infra 接入 agent-runtime 底座，保留现有链路，可降级是必要条件。

- 继续使用现有执行入口，通过环境变量选择旧链路或新 Runtime；切换通过重新部署生效。
- CLI 由环境提前预装，本次重点是 KC 接入、CLI 调用身份和父子运行租约协作。
- 保留会话上下文，支持后端切换后的续聊；停止和写入结果不确定时先核对，避免重复执行。
- 联调环境：知识引擎01。

用户当前要求先整理方案和测试用例，暂不改代码。环境变量名称暂定 `AGENT_EXECUTION_BACKEND`，具体配置和接口细节待实施时确认。

## 已形成的材料

- [双链路接入与降级方案](/Users/bytedance/Projects/knowledge-compiler/docs/agent-runtime-dual-backend-design.md)
- [关键测试计划](/Users/bytedance/Projects/knowledge-compiler/docs/testing/agent-runtime-dual-backend-test-plan.md)

两份文档均为待实施设计。待确认：评审结论、远端停止确认能力、预装 CLI 的运行身份，以及开发完成和联调的验收口径。

来源：2026-11-02 聊天《知识编译-agent infra切换》（ID `01a19b43-a2c1-7983-9f52-f4d3fc12ae72`）中的用户要求；同日晚间读取上述方案和测试计划确认材料已形成。当前工作分支为 `codex/agent-runtime-migration-7372003123`，基于 2.6.0。

## 协作安排

11-02 20:14，我在飞书确认 Agent Infra 各模块周会时间可行：11-04（周三）14:00–15:00。群内陈浩津另提出与李彬讨论 Action 对 Agent Infra 的需求，具体讨论时间与结论待补充。

来源：[周会安排](https://applink.feishu.cn/client/chat/open?openChatId=oc_2b0aff79f4c7c9797be58b61bf28f692&position=187)、[我的确认](https://applink.feishu.cn/client/chat/open?openChatId=oc_2b0aff79f4c7c9797be58b61bf28f692&position=190)、[Action 需求讨论提议](https://applink.feishu.cn/client/chat/open?openChatId=oc_2b0aff79f4c7c9797be58b61bf28f692&position=186)。

## Meego 状态（11-02 读取）

- P0，状态"待排期"，当前节点"需求排期"；模块：知识挖掘（图谱/编译/本体）。
- 需求文档、技术文档、描述均为空；Server / FE 开发节点未开始，无排期和估分。
- 只有一个未完成子任务"测试用例"（`7372003124`），无评论。
- 版本字段是旧值（规划 v2.5.0，实际上车 v2.7.0，预计发布 10-15），不作为本次期限。

Meego 状态和实际进度不一定一致，以我的反馈为准。

## 跟进

- 在 Codex「知识编译-agent infra」分区讨论本需求。
- 自动化"Agent Infra 工作日晚间进展"（ID `agent-infra`）：周一至周五 22:00 跟进当天进展、卡点和下一步，有新进展才写回本页。需求结束时停掉。
