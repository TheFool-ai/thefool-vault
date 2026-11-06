---
created: "2026-11-06"
updated: "2026-11-06"
type: note
---

## 核心结论

DeerFlow 从围绕研究角色组织协作的深度研究系统，重写为以 Coding Agent 为内核、按需加载 Skills 的通用 Agent 运行时。[团队介绍][6]

## 当前状态（2026-11-06）

| 项目 | 可确认的状态 | 依据与边界 |
| --- | --- | --- |
| DeerFlow 1.0 | 保留为旧版本分支，主要开发已转向 2.x | 官方说明 1.x 保留在 main-1.x，仍欢迎贡献；不能说旧版已删除或完全无人维护。[12][12] |
| DeerFlow 2.x | 当前开发主线，持续发布 | 官方最新 Release 为 2026-11-04 发布的 2.2.0，新增与完善目标驱动定时任务、多实例部署、插件平台、知识检索及模型管理能力。[13][13] |

## DeerFlow 1.0：把研究组织成一个团队

**时间线。** 团队回顾称，2025 年 3 月推出 LangManus，5 月更名为 DeerFlow，并升级前后端架构。早期 LangManus 文章也补充了更名说明。2025 年 5 月 16 日已有 DeerFlow 专场分享。[来源：团队回顾][6]、[LangManus 介绍][10]、[分享纪要][5]

**工作方式。** 用户提出课题，系统先理解和搜索背景，再形成计划；用户可以反馈修改。研究团队按分工搜索、读取网页、执行 Python，最后生成报告。[来源：分享纪要][5]

典型角色包括 Coordinator、Planner、Researcher、Coder、Reporter；不同阶段还出现过 Supervisor、Browser，角色列表不宜跨版本混用。

**关键价值。** 从一次搜索摘要发展为“规划 → 收集 → 计算 → 汇总”的研究过程，能输出结构化、有引用的报告。研究是预先组织好的主要任务，新增能力通常需要增加节点或修改图。[来源：团队回顾中的版本比较][6]

**推动重写的原因。** 团队发现社区还用它做数据分析、PPT、内容生产和运维。共同需求是持续规划、操作文件、执行代码、交付产物，于是把研究能力下面的执行基础抽出来，做成通用运行时。[来源：团队回顾][6]

## DeerFlow 2.0：以 Coding Agent 为内核

团队介绍称，2.0 在 2026 年春节期间推出，与 1.0 完全重写，定位为 Super Agent Harness，基于 LangGraph，核心是支持 Skills、Memory 的 Coding Agent。[来源：团队架构介绍][6]

**最重要的变化是能力如何组织。**

| 维度 | 1.0 | 2.0 |
| --- | --- | --- |
| 主体 | 按研究角色组织的图 | Lead Agent + Middleware + 动态 Sub-agent |
| 扩展 | 改图、加节点 | 加 Skill 或 Tool |
| 研究 | 产品的主要流程 | 可按需使用的一个 Skill |
| 上下文 | 共享研究状态 | 子任务上下文隔离、摘要压缩、文件保存中间结果 |
| 执行 | 以 Coder 的 Python 执行为主 | Bash、文件读写、Python 等通用执行环境 |
| 跨会话记忆 | 团队对照表标为无 | 用户画像、时间线、事实等长期记忆 |

上表按团队文章描述的版本整理。[来源：版本对照][6]

**一个例子。** 用户给两份 CSV，要求合并、找异常、生成图表和报告。主 Agent 可加载 data-analysis Skill，在沙箱用 DuckDB / Python 处理数据，再调用可视化和报告能力。研究、数据分析、网页制作共享同一套执行底座。

**Skills 与沙箱的分工。** Skill 提供流程、领域知识、脚本、模板，按需加载；沙箱提供实际读写文件和执行命令的环境。Local 模式直接使用宿主机；Docker / Kubernetes 模式提供容器执行方式，隔离边界取决于部署模式。[来源：Skills 与 Sandbox 章节][6]

## 来源

2026-11-06 读取飞书材料及官方 GitHub。文档建档日期与正文事件日期分开。

- [5][5]《基于 LangStack 的全新 Deep Research 开源项目——DeerFlow》智能纪要：2025-05-16，李昕分享；自动纪要中的产品名转写存在错误，技术概括结合团队文章理解。
- [6][6]《DeerFlow 2.0：再攀高峰》：李昕的团队技术介绍；2026-02-28 建档，owner 桂勇。正文后续有更新，不能把所有内容都归到建档日。
- [10][10]《是的！我们做了一个 Manus Agent》：团队成员、LangManus 架构及后补的 DeerFlow 更名说明。
- [12][12] DeerFlow 官方 README：1.x 分支保留与开发主线转向 2.0 的说明。
- [13][13] DeerFlow 2.2.0 官方发布记录：2026-11-04。

[5]: https://bytedance.larkoffice.com/docx/MPnHdTfMfoDfUKxkyl2cJvevnvb
[6]: https://bytedance.larkoffice.com/docx/KI9bdFRN2o1IHWxieowckiXKnr0
[10]: https://bytedance.larkoffice.com/docx/OZoKdDSCmomWfTx2Sd1chLMQnpe
[12]: https://github.com/bytedance/deer-flow/blob/main/README.md
[13]: https://github.com/bytedance/deer-flow/releases/tag/v2.2.0
