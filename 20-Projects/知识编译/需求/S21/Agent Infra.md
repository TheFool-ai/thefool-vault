---
created: 2026-11-02
updated: "2026-11-10"
type: requirement
requirement_created: 2026-08-31
meego_id: "7372003123"
---

知识编译项目下的技术需求，Meego：[【知识编译】Agent Infra](https://meego.larkoffice.com/xqd1pw/story/detail/7372003123)。

## 当前进展（11-09）

01 已切到 agent_runtime，流式、跨后端续聊、历史卡片、引用与 Skill 传入、断连后继续执行及降级切回通过接口级验收。空间与任务上下文改动 c6b4e5e2 已推送，尚未部署。CLI 业务身份、Task 工作目录对齐和新产物出卡仍未闭环；11-16 提测目标不变。

## S21 安排（11-05 更新）

- 我的优先级清单仍为 **P1**；11-04 曾待线下讨论，11-05 团队晚会已安排按 **S21、2.7.0** 推进。
- 目标仍为完成沙箱接入、测试与上线，并支持降级。
- 最新节点：**11-16 开发完提测**，我与杨宇航协作，QA 赵林柳；计划做双线效果评测。11-02 的开发、联调周次已被此安排替代。
- Meego 当前优先级仍为 P0、节点为“需求排期”，本页按我的最新清单记录；外部工作项未修改。

来源：11-04 我的 [S21 清单](S21需求.md)；11-05 21:36 萧启程发布的[晚会安排](https://applink.feishu.cn/client/chat/open?openChatId=oc_2b0aff79f4c7c9797be58b61bf28f692&position=219)。11-06 只读 Meego 仍为“需求排期”，不据此否定新排期。

## 计划与进展

| 阶段 | 时间 | 目标 | 进展 |
| --- | --- | --- | --- |
| 开发与提测 | **2026-11-16 开发完提测** | 我与杨宇航协作完成接入 | 双链路已实现，11-09 部分接口验收通过；身份、工作区与新卡片闭环待完成 |
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

**11-03 当时待办**：评审 Runtime 公开流与状态/停止确认能力、CLI 身份及父子分布式锁协作、卡片可信业务回执、`@`/Skill 兼容，以及两种沙箱策略的文件与生命周期边界，再推进开发。当时功能测试、知识引擎01联调尚未开始，后续结果见下文。

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

以上为早期方案和测试设计，现有流程页是迁移参考；后续实现与验收以下文为准。远端停止确认、CLI 运行身份与完整验收仍需补齐。

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

## 11-06 实现与剩余交付

我推动双链路实现并要求推送，KC f0537652 已推送；覆盖双 trigger、流式接入、会话恢复、已有卡片与回退。OpenCode 1.18.25 派生镜像已预装CLI和21个正式Skill，已发布并在知识引擎01完成真实沙箱启动、健康和CLI验证；构建文件移入agent_runtime_control，e7a7260已推送。本地回归9,879项通过、317项跳过，3项失败在原基线复现。

先推进分离沙箱，共用沙箱仍需底座接口。下一步部署KC并绑定Control环境，补齐用户凭据、Run及分布式锁绑定、写入回执到新卡片，再做完整端到端验收。镜像启动验证不等于KC主链路已部署。

来源：11-06 Codex《知识编译-agent infra切换》（local，01a19b43-a2c1-7983-9f52-f4d3fc12ae72），已核对测试、镜像发布、模板注册、真实沙箱和推送输出。[KC分支](https://code.byted.org/dp/knowledge-compiler/tree/codex/7372003123-agent-runtime-integration)、[镜像构建分支](https://code.byted.org/dp/agent_runtime_control/tree/codex/7372003123-opencode-kb-cli)。

## 11-08 联调验收状态

我在01部署后要求验收。Control就绪、VeraG到KC的鉴权及GraphQL基础路由通过；新运行链路的完整验收仍被前置条件阻塞。

- KC仍使用legacy，Control连接及环境绑定未就绪。
- KC模块授权未就绪，编译空间与模型入口受阻；CLI沙箱模板当次查询未找到。
- 下一步补齐新后端启用、模块授权、模板与环境绑定，再验流式、断连续跑、续聊、卡片、引用、Skill、写入与降级。11-06的镜像启动验证保留为历史结果，尚无本轮端到端通过证据。

来源：11-08 23:49–23:56 Codex《知识编译-agent infra切换》（local，ID 01a19b43-a2c1-7983-9f52-f4d3fc12ae72），本人部署与验收要求；验收结果文件 /tmp/kc01-accept.X9rxDZ/result.json 标记日期为11-08、result为blocked，原始检查已核对。

## 11-09 接入验收与后续边界

我继续推进01接入并要求逐项验收，先前的新后端启用、模块授权和模板绑定前置阻塞已解除。01 当前使用 agent_runtime 与 kc_agent_runtime 环境。

- **已验证**：流式正文112个增量；旧链路切新链路后恢复原会话内容；原 Schema 卡片保持同一 message_id 且仅一张，关联产物可读；`@` 引用身份与所选 Skill 正文传入；沙箱执行 CLI 命令并保存工具结果；前端断连后后台完成并落库1,878字；降级后可切回新链路。属于接口级验收，尚未完成全部页面业务验收。
- **我要求的上下文改动已交付**：每轮系统提示词动态注入 space_id、space_name、task_id，去掉 task_title，减少重复选择空间和任务。提交 [c6b4e5e2](https://code.byted.org/dp/knowledge-compiler/commit/c6b4e5e299e82e52e443ec2c62088c2d25c1563f) 已推送，相关203项测试通过；尚未部署到01。
- **剩余验收缺口**：CLI 实际读取 Artifact 仍返回 login_required，引用身份传入不等于正文已读。需接通页面用户身份、父 Run 与分布式锁，补齐文件读写、可信业务回执和新卡片。运行沙箱与 KC Task 文件仍未对齐，不能把历史卡片恢复算作新产物出卡通过。

### 架构方向与待定方案

我明确要求从全局设计可替换内核：Cloud Agent 直接调 KC API，Sandbox Agent 用 CLI 调同一套能力；KC 持有会话、权限、任务文件、产物登记与卡片。页面已确定空间和任务，不再要求用户登录 CLI、选择项目或应用。普通文件保留自动登记，不能改成必须手动提交。

以下仍是方案，未实施或验通：

- 复用持久化 Task 目录，让原生 write/Bash 与 CLI 操作同一份文件。mnt_config 可复用，但真实存储源、挂载点和 outputs/ 采集范围尚需对齐；两侧交叉读写与净变化采集待验证。
- KC 接收 runtime.file_changes，在成功收尾后按普通文件净变化登记；Schema 按显式提交的业务回执出卡，并按 Run 去重、补办。现有类与方法拆分仍待实施。
- 我先要求按页面 Cookie 复用方式设计，后继续比较应用 UAT 与 Run 凭据。服务端保管 UAT、沙箱只拿短期 Run 凭据是助手建议；最终凭据方案待确认，尚无免交互签发和注入实现。

### 11-09 团队接入讨论

- 我向杨宇航区分通用 Agent 与可控 runtime：前者通过 CLI 操作 KC 的持久化沙箱，后者希望挂载持久化目录并复用自己的执行沙箱。杨宇航19:25表示准备做端到端测试，尚无对应结果。
- 萧启程确认 mnt_config 支持多个路径；动态挂载会影响当前 MiniBase 预热，启动耗时增加约10秒是其反馈口径。实际 Task 路径、可写范围、采集目录与冷启动仍需联合验证，不能把“支持多路径”当作原文件已挂通。
- 我与于子奇讨论新增页面身份访问模式；现有 CLI 不直接支持页面 Cookie，应用 UAT 另需绑定应用和资源授权。最终选择继续收敛。

来源：11-09 与杨宇航的私聊（chat_id `oc_432fb642ab4b4c76a2713542c04ff66f`，11:28、19:25）；「萧启程, 石浩枫, 吴腾超」17:15–19:23，关键 message_id `om_x100b602cbd05c4a8cf9434a9750ec54`、`om_x100b602e9f495880cf9909a20fd588f`；与于子奇私聊（chat_id `oc_0d29528ea104e6c65fa9895f1c595a5f`，20:26–23:46），message_id `om_x100b602f8bd44508b4fc5332abe9b57`、`om_x100b602ae08efca0dfc06dd0c0cea55`。

下一步：确认身份委托与工作区契约，再统一实施；部署上下文改动，验通真实业务读取、文件写入到新卡片，以及跨后端继续编辑。按11-16提测目标检查剩余交付。

来源：2026-11-09 Codex《知识编译-agent infra切换》（local，ID 01a19b43-a2c1-7983-9f52-f4d3fc12ae72），已读取当日实际讨论、验收和推送输出；[01验收记录](/Users/bytedance/Projects/knowledge-compiler-agent-runtime-7372003123/docs/reports/2026-11-09-agent-runtime-knowledge01-acceptance.md)。架构讨论见[原飞书方案](https://bytedance.larkoffice.com/docx/H7dJdIBB6oFE6hxB1VxclEOQnsg)，其中目标方案不作实现结果。
