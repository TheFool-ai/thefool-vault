---
created: "2026-11-10"
updated: "2026-11-11"
type: note
---

## 核心判断

NVIDIA Auto Ontology 的已实现主链路，是把关系数据库编译成可检索的业务语义层，辅助 Agent 问数：业务词对应哪些字段、指标怎么算、表之间怎么关联。更接近我们知识编译中的数据语义方向。

它的自动建模以表为单位，消费侧仍由 LLM 生成 SQL，再做静态校验、数据探查和修复。“确定性查询”不能理解为整个自然语言到 SQL 的过程都由确定性编译器完成。[编译入口][compile]、[SQL 生成][sql-gen]

本次分析固定于源码 `fc43a82600e18b19d159c52023f54f5572f537ac`。结论来自静态源码与官方说明，未运行服务或验证问答准确率。作者：NVIDIA；读取日期：2026-11-10。

## 解决的问题与设计思路

AI 基于实现的归纳：企业问数需要先确定业务含义。模型即使能写出可执行 SQL，也可能选错金额字段、日期口径、地区归属或关联路径。数据库结构提供物理事实，业务用法还分散在字段描述、历史查询和人的经验中。

它的思路是将反复需要的解释工作提前完成：自动形成语义草稿，人审阅和认证，再让查询 Agent 复用。业务定义、物理映射和可执行 SQL 保持关联，查询时据此生成并检查 SQL。[编译入口][compile]、[SQL 生成][sql-gen]

| 问题 | 方案对应 |
| --- | --- |
| 业务词难以准确定位到数据 | 术语、别名、属性与物理表列映射 |
| 指标和筛选口径容易每次重写 | 沉淀可复用 SQL 属性，支持人工确认 |
| 多表关联容易猜错 | 编译语义外键与桥表模式，查询时搜索关联路径 |
| 答案难以检查 | 分层校验，返回 SQL、结果与处理步骤 |

这套方案的主要价值在于让业务解释可积累、可维护、可复用。自动抽取和校验仍不足以保证业务正确性；需要用真实问题验证草稿与口径。

## 它编译出了什么

| 产物 | 表达什么 | 示例 |
| --- | --- | --- |
| Catalog | 物理数据库、Schema、表、列、外键、采样与字段特征 | `sales.invoicelines.extendedprice` |
| Term | 业务概念、描述、别名，以及对应的表 | Invoice Line |
| ColumnAttribute | 业务属性及其物理列映射 | Invoice Line 的金额 |
| Semantic FK | 一列引用另一业务属性，供关联路径搜索 | 发票行引用发票标识 |
| SqlAttribute | 挂在 Term 下的可复用 SQL，涵盖计算、筛选和桥表关联 | 销售额计算、订单与商品的多对多关联 |

这些定义存在 Postgres 的实体表和关联表中；向量索引用 pgvector。“图”描述的是关联结构，当前部署不要求独立图数据库。业务明细主要留在源库，查询时执行 SQL 取数，采样值另进入 Catalog。[关系模型][schema]、[官方架构][readme]

## 自动构建链路

入口是 `run_semantic_compilation()`，主要有四段：[源码][compile]

1. 逐表生成 Term 和 ColumnAttribute，并向量化。
2. 解析 Semantic FK，形成跨表语义关联。
3. 从历史 SQL 建议 SqlAttribute。
4. 为桥表生成可复用的 JOIN SQL。

### 逐表生成术语，模型输出受字段清单限制

`process_table()` 先采样和分析列，保存样例值、唯一性信息、日期存储格式等。结合已声明外键和模型建议识别外键列；非外键列进入业务属性候选。随后让模型给表命名、写定义、分配属性。[逐表处理][table]

Term 抽取的约束很具体：[提示词与清洗逻辑][term]

- 强烈偏好一表一个 Term；仅在有明确理由时拆分。
- 候选列只能分配到一个 Term，不允许凭空增加物理列。
- 明确禁止提出 `IS_A`、`PART_OF`、`ROLE` 关系。
- 返回结果经过 Pydantic 和代码清洗；未知列丢弃、重复分配去重、漏分配列补到首个 Term。
- 同义词另行抽取，只收表描述中明确出现的别名。

同名 Term 不直接跨表融合。持久化时发现其他表已占用名称，会加数据库、Schema、表名限定。并行抽取、按固定表顺序提交，减少同名归属受完成先后影响的问题。[编译调度][pipeline]、[名称分配][terms]

AI 判断：它优先保住“概念到物理数据的映射可用”，自动建模并未覆盖企业概念体系的完整归纳与融合。

### 关系解析采用已知结构、向量召回和模型选择

已有外键优先直连到目标 ColumnAttribute。目标无法直接确定时，用列名、描述和样例检索候选，过滤范围包括同一数据库、唯一列，并排除本表；再让模型选目标。模型放弃时，才尝试用样例值在候选物理列中的包含关系兜底。[关系解析][fk]

这里没有要求每条模型选出的边都经过全量数据验证。样例匹配也不能证明完整引用完整性。

### 从历史查询提炼口径

`suggest_sql_attributes()` 从 Term 关联表的历史 SQL 中抽取表达式，把候选列表前十项交给模型判断是否值得复用；再补成可校验的 SELECT，保存为 SqlAttribute。没有历史 SQL 的 Term 会跳过这一步。当前 `_usage_score()` 固定返回 `0.0`，所有表达式同分，沿用插入顺序；代码注释中的近三个月使用量排序没有生效。[源码][sql-attrs]

桥表另走一条路径：识别连接多个实体角色的中间表，使用已知外键生成 JOIN SQL；要求只使用给定键，不添加业务过滤条件。[桥表处理][bridge]

AI 判断：历史 SQL 比字段名提供了更多真实用法，业务正确性仍需审阅。当前实现不能据此声称优先提炼了高频口径。

## 问题如何消费这些产物

主链路由 LangGraph 固定编排：[状态图][query-graph]

> 意图分类 → 提取问题实体 → 检索业务属性、术语和 SQL 资产 → 准备字段及关联上下文 → LLM 生成 SQL → 校验与修复 → 执行源库查询 → 返回答案、SQL 和过程。

`CandidatePreparationAgent` 把语义候选还原为物理列，选择一个锚点属性，调用 `find_join_path()` 搜索到其他目标列所在表的路径；再补关联表、业务定义和 SQL 片段。路径搜索在数据库范围内使用语义外键构建邻接关系，以 BFS 找最短路线，并对反向关联施加主键条件。[候选准备][candidates]、[路径搜索][paths]

最终 SQL 仍由模型合成。提示上下文包含物理结构、关联路径、SQL 属性、别名、可用历史示例等。它降低了模型猜表、猜字段和猜关联的空间。[SQL 生成][sql-gen]

校验分层处理：[SQL 校验][validation]、[状态图][query-graph]

- SQL 解析、表列引用和部分聚合错误，用代码检查。
- 意图匹配仍有 LLM 判断。
- 字面值、JOIN 路径和 JSONB 路径的主动数据探查按配置启用。
- 执行失败或空结果可触发修复；SQL 重建最多七次。
- 一些软检查在重试较多后会放行，不能把“走过校验流程”视为业务语义必然正确。

独立的 `check_answerable` 供调用方做预检。当前 coverage 是距离过滤后的 ColumnAttribute 命中所覆盖的问题实体数 / 总实体数；它衡量实体覆盖，不证明 JOIN、计算口径、权限和数据时效都满足。[覆盖计算][coverage]

## 审阅、更新和消费接口

Term 的名称、描述，ColumnAttribute 和 SqlAttribute 带人工认证状态，可以在 UI / API 编辑与确认。认证状态表达已审阅，不能仅凭这些字段推断查询只允许使用已认证资产。[数据模型][schema]

当前语义编译默认启动时及前次结束约 24 小时后运行，也可手动触发。Term 构建阶段只选择尚未关联 Term 的表，后续外键、SQL 属性和桥表阶段仍会执行；Catalog 有重摄入和结构差异处理。已有 Term 的表发生字段变化后，语义属性怎样失效和重建，需要另做验证。[调度][scheduler]、[待编译表选择][datasources]、[Catalog 增量用例][incremental]

MCP 有意只暴露少量只读语义工具，如 `search_terms`、`get_term_columns`、`get_term_sql_attributes`、`check_answerable`，另有 `ask_question` 和 `check_readiness`。工具说明直接告诉 Agent 何时使用、应优先复用已有口径；没有把全部管理 API 暴露出来。[工具设计][mcp]

## 对知识编译的借鉴

以下为 AI 建议，未被确认为项目方案。项目目标见[本体建设](../20-Projects/知识编译/本体建设.md)。

1. **按消费动作设计编译产物。** 问数需要“词 → 字段 → 关联 → 公式”；推理、校验和 Action 应分别定义自己需要的可执行表示。
2. **把真实用法作为编译材料。** 字段描述之外，吸收经过确认的历史查询、筛选条件和关联方式，形成可复用资产。
3. **把约束放到代码里。** 模型负责提议名称和映射，代码负责字段白名单、归属、作用域、引用与结构校验。
4. **消费工具围绕任务设计。** Agent 应能查询业务含义、定位物理数据、取现有口径、判断覆盖程度；只提供整份本体下载还不够。

适合的最小验证：在一个限定数据集上，选包含业务别名、统一指标口径、多跳 JOIN 的真实问题，与仅给 Schema 的问数基线比较。分别测口径、关联、结果正确率，以及时延和模型调用成本。当前没有这些实测数据。

规则推理、约束优化和 Action 执行仍需单独设计。这次看到的主要能力支撑数据查询；其中的路径搜索与 SQL 校验，不能直接作为我们公理推理或动作闭环已经可复用的证据。

## 来源

下列源码均固定到同一提交；README 使用该提交版本。

[readme]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/README.md
[compile]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/semantic/compile.py
[schema]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/dal/schema.py
[table]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/semantic/visit_enter.py
[term]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/semantic/term_extractor.py
[pipeline]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/semantic/pipeline.py
[terms]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/dal/terms.py
[fk]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/semantic/semantic_fk.py
[sql-attrs]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/semantic/sql_attribute_suggester.py
[bridge]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/semantic/bridge_tables.py
[query-graph]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/retrieval/text_to_sql/text_to_sql_graph.py
[candidates]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/retrieval/text_to_sql/agents/candidates_preparation.py
[paths]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/dal/attributes.py
[sql-gen]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/retrieval/text_to_sql/agents/sql_from_semantic.py
[validation]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/retrieval/text_to_sql/agents/sql_parse_validation.py
[coverage]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/retrieval/entity_coverage/agents/coverage.py
[scheduler]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/ingestion_service/semantic_scheduler.py
[datasources]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/dal/datasources.py
[incremental]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/auto_ontology/catalog/tests/test_incremental_ingest.py
[mcp]: https://github.com/NVIDIA/auto-ontology/blob/fc43a82600e18b19d159c52023f54f5572f537ac/mcp/auto_ontology_mcp/tools.py
