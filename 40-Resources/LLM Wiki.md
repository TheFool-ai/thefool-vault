Karpathy 提出的一种个人知识库做法：让 LLM 持续维护一套互相链接的 Markdown 页面，而不是每次提问都回到原始资料里重新检索。

## 核心想法

RAG 每次提问都从零拼答案，知识不会积累。LLM Wiki 把“理解”提前编译好：新资料进来时，LLM 读完后去更新已有页面——改摘要、补关联、标出和旧结论冲突的地方。知识库因此越用越厚，而不是越堆越乱。

分工很明确：人负责找资料、提问题、判断什么重要；LLM 负责摘要、交叉引用、归档这些人最容易半途放弃的杂活。

> LLMs don't get bored, don't forget to update a cross-reference, and can touch 15 files in one pass.

## 三层结构

| 层 | 是什么 | 谁来改 |
| --- | --- | --- |
| 原始资料 | 文章、论文、图片、数据 | 只读，不改 |
| Wiki | 摘要、实体页、概念页、对比、综述 | LLM 全权维护 |
| Schema | `AGENTS.md` / `CLAUDE.md`，规定结构、约定和流程 | 人和 LLM 一起迭代 |

## 三种操作

- **Ingest（摄入）**：放进一份新资料，LLM 先和你聊要点，再写摘要页，同时更新所有受影响的页面。一份资料可能改动十几个页面。
- **Query（提问）**：LLM 先找相关页面再回答，并注明出处。好的回答要写回 Wiki，这样探索本身也会沉淀下来。
- **Lint（体检）**：定期检查矛盾、过时结论、孤立页面、缺失的概念，并提出值得补的问题。

原文还建议用两个辅助文件：`index.md` 按内容列出所有页面，`log.md` 按时间追加记录每次操作。

## 本库怎么用

- 人选方向、给材料、说哪些重要；AI 负责整理、关联和更新，见 [AGENTS.md](../AGENTS.md)。
- 页面还少，暂时用 [README](../README.md) 当索引，不单独维护 `index.md`；Git 历史代替 `log.md`。页面多到 README 装不下时再加。
- 工作和生活的实际进展记在日记和项目页，可复用的理解放进 `40-Resources`。
- 效果看的是用不用得上：下次讨论方案、写周报时，能不能找到旧记录并直接用上。页面数量不重要。

### Codex 怎么找到笔记

本库的 README 把主题和入口页连起来。开源 Codex CLI 的默认指令让模型按需用 `rg` 搜正文、用 `rg --files` 列路径，再读相关文件。终端里用 `@` 找文件时，会临时遍历目录，按路径做模糊匹配。截至 2026-11-12，公开主线里未见打开项目就把全库正文分块、向量化并持久保存的默认流程。[Codex 默认搜索指令](https://github.com/openai/codex/blob/c0cc9fc820f62e4dbdde68214dd6d792d6c8a7ee/codex-rs/protocol/src/prompts/base_instructions/default.md#L264) · [终端文件搜索实现](https://github.com/openai/codex/blob/c0cc9fc820f62e4dbdde68214dd6d792d6c8a7ee/codex-rs/tui/src/file_search.rs#L53-L89)

### Zoekt 怎么索引代码正文

Zoekt 给文件名和正文建带位置的三元组倒排索引。每三个相邻字符对应一份出现位置列表。搜 `retryPolicy` 时，假设选中 `ret` 和 `Pol`，就先找两者起点恰好相距 5 个字符的位置，再核对完整字符串。正则也能用其中必定出现的文本缩小候选范围。索引分片落盘，适合反复跨仓搜符号、日志和代码片段。面对“失败后在哪里重试”这样的提问，仍需要人或 Agent 提出 `retry`、`backoff` 等搜索线索。

来源（2026-11-12）：[Zoekt 设计文档](https://github.com/sourcegraph/zoekt/blob/ad747a07af56ea767ab659de5cf445bad5500e79/doc/design.md) · [查询时如何选三元组](https://github.com/sourcegraph/zoekt/blob/ad747a07af56ea767ab659de5cf445bad5500e79/index/indexdata.go#L343-L365)。

## 团队实践：Context

Context（context4ai/context）把“提前编译理解”用在研发知识上。Agent 读代码和文档，按问题组织知识页，每个小节保留证据入口。下次提问先读知识页，需要核实实现时再读对应版本的源码。来源变化时，按影响范围重审和更新。

值得借鉴的是把出处记到小节。比如“哪些失败会触发重试”要能查到判断条件所在的文件、行和版本。工具能检查引用目标是否存在，结论有没有漏掉例外，仍靠阅读和审阅判断。

来源：context4ai，[中文项目说明](https://github.com/context4ai/context/blob/main/README.zh-CN.md)、[知识地图校验实现](https://github.com/context4ai/context/blob/main/packages/context-cli/src/project/knowledgeMapCoverage.ts)，2026-11-11。

### Agent Graph 的核心价值

我的判断（2026-11-11）：人可以事先规定什么条件下允许做什么，Agent 根据当前材料判断这一步怎么做，宿主系统根据证据决定流程能否继续。选型看三个特征：

1. **流程边界清楚。** 什么时候开始、必须停在哪里、满足什么条件可以继续，都能提前定义。实际路径可以分支、回退或重试。这解释了为什么需要状态机。
2. **步骤内部需要判断。** 即使已经确定当前步骤，仍要结合材料理解意图、权衡选项或生成内容。这解释了为什么需要 Agent。
3. **推进条件可以核验。** 产物版本、校验结果或人的明确决定，都可以作为切换状态的依据。质量可以由人判断，系统能核实谁确认了哪一版即可。这让 Agent 的工作结果接得上状态机。

流程长、跨会话、多人协作、执行频繁、跳步代价高，都会放大收益。判断是否适用，先看上面三个特征。

#### Context 如何续跑知识生产流程

Context 用 Agent Graph 管理生产步骤。工作图写明每一步的前置条件、可执行动作和完成证据。宿主读取工作区事实，工作图据此选出下一步，只给 Agent 这一步需要的材料。比如草稿落盘、审核待完成，换个会话仍然进入审核。可以直接用这组事实测试路由，写作质量另行评估。

接入的前提是宿主能验证事实。审核结果若只记作“已通过”，改稿后就可能误用旧结果。Context 把写命令绑定到工作区修订版本，能拒绝基于旧状态发出的写入。

普通状态机也能表达“审核后才能构建”。Agent Graph 额外约定了执行者到达审核节点时必须读什么、谁能决定、哪个动作只读、哪个动作可以落盘。Context 的审核规程区分“改完给我看”和“改完直接通过”：前者改完重出报告，后者核实修改后可在原授权范围内通过，新混入的候选页仍待审。Graph 选择规程，Agent 理解反馈，Context 校验版本和范围并写入决定。队列、重试调度等执行能力仍由宿主或工作流引擎提供。[脱敏运行回放](https://context4ai.github.io/context/case-studies/workflow/?lang=zh) · [审核对话规程](https://github.com/context4ai/context/blob/main/packages/context-cli/context-workflow/resources/dialogue/knowledge-review.md)

来源：context4ai，[Agent Graph 是什么](https://ttkb.byteintl.net/ttkb-context/context/pages/12aee1b47052473c9bf0ed43e72a2994.html)、[Agent Graph 中文 README](https://github.com/context4ai/agent-graph/blob/main/README.zh-CN.md)、[接入场景](https://github.com/context4ai/agent-graph/blob/main/docs/zh-CN/adoption-paths.md)，2026-11-11。

## 团队实践：TTKB

AI 对 TTKB 手册的判断（2026-11-11）：最值得解决的是团队反复为相似任务重建业务上下文。一次 Oncall 排查的结论可能留在群聊，修复落在 MR，排查顺序只存在于当次 Agent 会话。下次换人、换工具，仍要重新拼出该查什么、为什么这么查。

- **让下次任务用得上。** 团队围绕一类任务把代码、文档、群聊和 Trace 整理成知识包。业务事实可以写成 Markdown，可复用的操作步骤可以写成 Skill。Agent 执行时逐步搜索、定位和读取所需内容。
- **让经验跟得上变化。** 从任务总结或代码变更提取新事实，发起知识变更，审核发布后供下一轮使用。团队可以共享同一份维护结果。
- **判断维护值不值。** 固定 Agent 运行环境、仓库和题目，对比有包和无包的任务通过率、Token 和耗时。是否值得持续维护，要看目标任务上的实测收益。

适用条件是任务反复出现、完成它需要团队特有知识、知识会变化，而且下一次任务有机会用到更新。手册中的多人直播团队用 Lynx 调试经验举例。

来源：TTKB 团队，[使用一览图](https://bytedance.larkoffice.com/wiki/CodgwQzUXiZdkukgmPrcB5bxn1d#doxcnuFM6zV7K16smWTZGnhxqDe)、[业务开发实践](https://bytedance.larkoffice.com/wiki/CodgwQzUXiZdkukgmPrcB5bxn1d#KJUddrhxhobqwDxGMlcljOsTgxh)、[知识效用评测](https://bytedance.larkoffice.com/wiki/CodgwQzUXiZdkukgmPrcB5bxn1d#PuxEdjgDEoMAfZxkR0OlbBBvgKV)，2026-11-11 查阅。

## 来源

Andrej Karpathy，[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)，2026-04-04。2026-11-02 阅读正文，未看评论区。
