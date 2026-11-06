---
created: 2026-11-02
updated: "2026-11-06"
type: requirement
requirement_created: 2026-08-31
meego_id: "7372003123"
---

知识编译项目下的技术需求，Meego：[【知识编译】Agent Infra](https://meego.larkoffice.com/xqd1pw/story/detail/7372003123)。

## S21 安排（11-05 更新）

- 我的优先级清单仍为 **P1**；11-04 曾待线下讨论，11-05 团队晚会已安排按 **S21、2.7.0** 推进。
- 目标仍为完成沙箱接入、测试与上线，并支持降级。
- 最新节点：**11-16 开发完提测**，我与杨宇航协作，QA 赵林柳；计划做双线效果评测。11-02 的开发、联调周次已被此安排替代。
- Meego 当前优先级仍为 P0、节点为“需求排期”，本页按我的最新清单记录；外部工作项未修改。

来源：11-04 我的 [S21 清单](S21需求.md)；11-05 21:36 萧启程发布的[晚会安排](https://applink.feishu.cn/client/chat/open?openChatId=oc_2b0aff79f4c7c9797be58b61bf28f692&position=219)。11-06 只读 Meego 仍为“需求排期”，不据此否定新排期。

## 计划与进展

| 阶段 | 时间 | 目标 | 进展 |
| --- | --- | --- | --- |
| 开发与提测 | **2026-11-16 开发完提测** | 我与杨宇航协作完成接入 | 已有方案及 88 项测试设计；新增实现、提测结果待补充 |
| 效果评测 | 随提测对齐 | 双线效果评测；QA 赵林柳 | 测评口径、环境与结果待补充 |
| 上线 | **S21，2.7.0** | 沙箱接入、可降级 | 尚无正式上线结果 |

## 范围

11-02 晚间已明确：从自研 Agent Infra 接入 agent-runtime 底座，保留现有链路，可降级是必要条件。

- 继续使用现有执行入口，通过环境变量选择旧链路或新 Runtime；切换通过重新部署生效。
- CLI 由环境提前预装，本次重点是 KC 接入、CLI 调用身份和父子运行的分布式锁协作。
- 保留会话上下文，支持后端切换后的续聊；停止和写入结果不确定时先核对，避免重复执行。
- 联调环境：知识引擎01。

11-02 至 11-04 的工作先限于方案和测试用例；11-05 已给出开发提测安排，实施拆分继续对齐。环境变量名称暂定 `AGENT_EXECUTION_BACKEND`，具体配置和接口细节待实施时确认。

## 11-03 方案收敛

- **已形成的产物**：完善全局、规则链与模块图解；补充当前自研链路泳道和六类 Hook 参考；测试计划扩为 88 项设计用例（P0 82 项、P1 6 项）。文档与图表检查通过，功能用例尚未实现或执行。
- **晚间完整方案补齐**：22:04 后按[概要设计](https://bytedance.larkoffice.com/wiki/CFtuwQT4ji31pOkfUtFcpslSn4f)整理为完整技术方案，覆盖现状与目标、各模块、接口与数据、实施步骤和验收。仍只修改文档。
- **四项核心验收要求**：同一 HTTP 入口下保留两个内部 trigger 并可切回旧链路；流式输出兼容；KC 正常保存会话及现有卡片；保留 `@` 引用和 Skill 能力。
- **新底座通过沙箱接入**：Code CLI 自主管理模型和工具循环，自行调用环境预装的 KC CLI；KC 在边界准备输入、接收公开事件、保存记录并完成业务收尾。只承诺公开返回的内容，不假定能获取完整内部过程。
- **旧流程继续作为参考**：保留现有泳道和 Hook 清单，对照业务职责如何承接；不要求把自研 Hook、压缩和工具循环搬进新 Runtime。方案按“当前链路 → 引入后链路 → 变化对照”讲解。
- **规则链与术语**：在 KC 边界拆分准备、执行、事件处理、收尾，后续统一使用“分布式锁”表述。

**当前待办**：评审 Runtime 公开流与状态/停止确认能力、CLI 身份及父子分布式锁协作、卡片可信业务回执、`@`/Skill 兼容，以及两种沙箱策略的文件与生命周期边界，再推进开发。功能测试、知识引擎01联调尚未开始。

来源：2026-11-03 聊天《知识编译-agent infra切换》（ID `01a19b43-a2c1-7983-9f52-f4d3fc12ae72`）中的用户要求，以及下列方案、参考页和测试计划。

## 11-04 沙箱策略与方案材料

- 我明确指出：Agent Runtime 的执行沙箱与 KC CLI 部分写动作操作的沙箱，目前是两套实例；方案需要同时覆盖**共用沙箱**和**独立沙箱**两类策略。
- 共用策略关注同一实例、Task 工作区、生命周期与局部取消；独立策略关注跨沙箱读写、内容与版本一致、两侧停止和恢复。共用实例的底座能力仍待核对。
- 本地方案与测试设计已补充两种策略；[知识编译接入 Agent Runtime 技术方案](https://bytedance.larkoffice.com/docx/H7dJdIBB6oFE6hxB1VxclEOQnsg)已形成，包含方案、Hook 参考与测试用例。当前仍是设计产物，实施和环境验证待推进。

来源：2026-11-04 Codex《知识编译-agent infra切换》（local，ID `01a19b43-a2c1-7983-9f52-f4d3fc12ae72`）中的用户要求、本地方案和测试计划；飞书方案正文已核实包含 shared/separate 两类策略。当日 S21 是否纳入仍待讨论，后续以 11-05 安排为准。

## 11-04 晚间取舍

- 我决定客户部署时先不打开新 Infra 开关，先保障内部稳定；S21 是否纳入仍待线下讨论。
- 我希望借本轮把工作自动化一起推进，但明确 **Action 的优先级更高**。
- 李彬请我本周给出排期；需结合稳定性、Action 优先级与两种沙箱策略评审重新收敛，不能直接沿用 11-02 的初步周次。

来源：2026-11-04 [我的优先级判断](https://applink.feishu.cn/client/chat/open?openChatId=oc_15d5cdd538df73b4975ff96d38c7790a&position=11547)、[排期请求](https://applink.feishu.cn/client/chat/open?openChatId=oc_15d5cdd538df73b4975ff96d38c7790a&position=11548)、[客户开关决定](https://applink.feishu.cn/client/chat/open?openChatId=oc_15d5cdd538df73b4975ff96d38c7790a&position=11550)。

## 11-05 对接边界与分工

- **分层复用**：业务侧各自定义 Agent、任务和产品形态，底层复用 Runtime、空间相关基础能力及 Skill Hub；逻辑空间与沙箱文件目录要区分，具体抽象和接口仍需细化。（22:27、39:10–49:39）
- **业务入口保留在 KC**：KC 触发运行、把任务托管给 Infra；执行沙箱预装 KC CLI，通过 CLI 调 KC HTTP 接口，流式消息回到 KC 再给前端。（54:12–57:03）
- **对接目标为共用沙箱**：我说明当前 CLI 写动作操作的是 KC 自建沙箱，切换时希望与 Infra 共用，需要调整文件、持久化与实例复用。先前两类策略继续作为方案参考，尚无功能验证结果。（55:32）
- **职责**：杨宇航侧重 kernel/Infra，我侧重把 kernel 接到编译业务；本体 Action 的端到端结果由编译团队负责，按需向 Infra 提需求。（32:43–34:25）
- **调度待对齐**：当前 KC 通过 BDB 回调触发任务；会上 Infra 提出统一调度方向，迁移协议、存量任务与验证方式待定。（57:07–57:49）

来源：11-05 11:16 开始的[《聊下agent infra》原始逐字稿](https://bytedance.my.larkoffice.com/minutes/obmy16g8u721mz4g16rk6k52)。提测与版本节点以当晚[晚会安排](https://applink.feishu.cn/client/chat/open?openChatId=oc_2b0aff79f4c7c9797be58b61bf28f692&position=219)为准，计划尚未充当开发结果。

## 已形成的材料

材料位于知识编译代码仓库：

- [飞书技术方案](https://bytedance.larkoffice.com/docx/H7dJdIBB6oFE6hxB1VxclEOQnsg)。
- 双链路接入与降级方案：`/Users/bytedance/Projects/knowledge-compiler/docs/agent-runtime-dual-backend-design.md`
- 现有自研流程泳道与 Hook 参考：`/Users/bytedance/Projects/knowledge-compiler/docs/agent-runtime-current-flow-reference.md`
- 关键测试计划：`/Users/bytedance/Projects/knowledge-compiler/docs/testing/agent-runtime-dual-backend-test-plan.md`

目标方案和测试计划均待实施；现有流程页是迁移参考。待确认：评审结论、远端停止确认能力、预装 CLI 的运行身份，以及开发完成和联调的验收口径。

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

- 在 Codex「S21-知识编译-agent infra」分区讨论本需求。
- 纳入 [S21 统一晚间跟进](S21需求.md#跟进安排)。本需求确认结束后停止本项跟进，其他 S21 需求继续。
