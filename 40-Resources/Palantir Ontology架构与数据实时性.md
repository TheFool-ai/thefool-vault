记录日期：2026-11-02。讨论起点是 Chad Wahlquist 的两条帖子及可见评论，重点是 Ontology 的运行架构，以及海量订单、客户数据的规模和实时性问题。

核心理解：Palantir 把数据、业务逻辑、动作和权限组织成统一的业务运行系统。海量实例由底层存储、索引和计算处理；实时性取决于增量链路、查询可见性和跨系统写入各自的保证。

## 两条帖子的主张

- [2026-09-23 原帖](https://x.com/chadwahl/status/2102782410681393629)：随着业务对象、关系、逻辑和动作日志进入 Ontology，它们也进入可搜索范围。搜索可以围绕业务关系展开。
- [2026-09-24 原帖及架构图](https://x.com/chadwahl/status/2103093160775708835)：Ontology 是中枢，外围还有模型接入、计算、Agent 生命周期、自动化、治理和开发发布工具。[查看架构原图](https://x.com/chadwahl/status/2103093160775708835/photo/1)。

图是平台能力总览，具体服务部署、底层数据库选型和一致性协议需要另看技术文档。

## Ontology 的核心

这里的 Ontology 是 Palantir 的产品系统名称。作者说明，可以导入、导出定义并转换成 OWL/RDF；这些定义只表达部分能力，产品还包含运行时。[作者解释](https://x.com/chadwahl/status/2103191917932798112)

| 部分 | 表达什么 | 供应链示例 |
| --- | --- | --- |
| Semantic | 对象、属性、关系和当前状态 | 客户、订单、供应商、库存及其关联 |
| Dynamic | 判断逻辑、计算和模拟 | 预测缺货，比较采购与调货方案 |
| Kinetic | 可执行的动作 | 创建采购单，调拨库存，修改订单 |

这个区分来自[作者对 Kinetic 与 Dynamic 的回复](https://x.com/chadwahl/status/2103191421888987320)。官方将其概括为 Data、Logic、Action、Security 的结合；权限需要覆盖读取、计算和执行动作。[Ontology 系统说明](https://www.palantir.com/docs/foundry/architecture-center/ontology-system)

架构图的外围能力可以归为五组：

| 能力组 | 职责 |
| --- | --- |
| Context Engineering | 接入数据、业务逻辑和外部操作系统，持续构建上下文 |
| Ontology 与向量、多模态、计算、工具服务 | 表达业务对象，提供检索、计算和可调用接口 |
| Agent 生命周期与业务自动化 | 构建、编排、评估 Agent，以定时、事件或 API 触发执行 |
| 模型接入、可观测性、安全治理 | 管理模型访问、追踪执行、限制权限、审批和审计 |
| 开发环境、应用、打包发布与企业自动化 | 构建应用，维护依赖，并在不同环境发布和迭代 |

来源：[AIP 架构说明](https://www.palantir.com/docs/foundry/architecture-center/aip-architecture)。

一个业务闭环示例（AI 概括）：供应商延期 → 更新订单状态 → 查找受影响的生产计划 → 比较处理方案 → 人或 Agent 选择 → 检查权限与审批 → 执行动作并写回 → 记录结果，触发后续流程。

## 海量订单和客户数据如何处理

### 业务定义与数据实例分开

订单有哪些字段、如何关联客户、允许哪些动作，属于定义层；几十亿条具体订单属于实例层。统一业务模型不意味着把全部数据放进一次模型上下文。

官方公开的 Object Storage v2（OSv2）把索引和查询子系统拆开，以便横向扩展，并描述了单一对象类型数百亿级的索引能力。容量描述不能直接推导任意查询的延迟和吞吐。[OSv2 架构](https://www.palantir.com/docs/foundry/object-backend/overview)

AI 对主要读链路的概括：

> 源数据库 → 全量初始化与持续增量 → 清洗和业务映射 → 对象存储与查询索引 → 过滤、聚合和关系查找 → Agent 获取任务所需结果。

例如查询“客户 A 即将逾期的订单”，应让后端完成客户、时间、状态过滤，再把相关结果交给 Agent。订单状态、金额、库存等精确且高频变化的字段，适合结构化读取；是否生成向量应按检索需求决定。这是工程判断。

### 增量索引与增量计算都需要成立

OSv2 默认计算数据源事务之间的差异，只索引发生变化的对象。假设十亿条订单中一万条变化，索引阶段可以只处理变化部分。[Funnel 批量与增量索引](https://www.palantir.com/docs/foundry/object-indexing/funnel-batch-pipelines)

但如果上游每次计算客户风险都扫描全部历史订单，增量索引无法消除这部分成本。评估规模时需要分别看：

- 总对象量：决定存储和索引规模。
- 每秒变更量：决定持续同步与计算压力。
- 单次变更的影响范围：决定关联视图和派生属性的更新成本。

以上三项是 AI 提出的评估框架。

## 实时性和一致性的边界

### 三种不同的保证

| 问题 | 官方机制与边界 |
| --- | --- |
| 外部订单库变化后何时在 Ontology 可见 | 流式接入和索引，文档描述为秒到分钟级；具体取决于整条链路 |
| Ontology 内 Action 执行后何时可见 | Action 完成后，随后开始的查询或 Action 可见其修改 |
| Ontology 与外部 ERP 是否同时成功 | 内部事务原子性不覆盖外部调用、Webhook 等副作用 |

来源：[流式索引](https://www.palantir.com/docs/foundry/object-indexing/funnel-streaming-pipelines)、[Action 一致性与隔离](https://www.palantir.com/docs/foundry/action-types/consistency-guarantees)。

端到端时效可以拆成：数据源捕获延迟＋传输排队＋转换计算＋索引提交＋应用刷新。索引 FAQ 提到 Flink checkpoint 默认每秒一次；这个频率只覆盖局部环节，不能当成端到端一秒可见的承诺。[索引 FAQ](https://www.palantir.com/docs/foundry/object-indexing/faq)

### 已公开的限制

以下是 2026-11-02 查阅官方文档时的说明，选型时应重新核对：

- 普通流式索引保留输入顺序，乱序事件可能导致对象状态错误；上游需要按主键分区并处理事件顺序。[流式索引限制](https://www.palantir.com/docs/foundry/object-indexing/funnel-streaming-pipelines)
- FAQ 列出的默认流式索引吞吐为每对象类型 2 MB/s，更高吞吐需要联系支持。这个数值不能外推为整个平台的吞吐上限。[吞吐说明](https://www.palantir.com/docs/foundry/object-indexing/faq)
- 普通流式对象的用户编辑存在限制。Direct datasources 处于 Beta，可提供低延迟写入、编辑和可配置的源时间戳排序；官方明确说明它以吞吐换取更强的写入能力。[Direct datasources](https://www.palantir.com/docs/foundry/object-indexing/direct-datasources)

### 新鲜数据与动作正确性分开处理

示例：Agent 读到库存为 10，思考两秒后准备分配 8 件，期间其他订单已经占用库存。同步延迟很低仍然可能超卖。

官方 Action 支持事务和隔离级别。新建的批量写 Action 默认使用快照隔离，对写入对象检测并发冲突；快照隔离仍可能出现写偏差，外部系统调用也不在同一事务保证内。[一致性与隔离边界](https://www.palantir.com/docs/foundry/action-types/consistency-guarantees)

AI 的设计判断：库存、付款、取消订单等操作，应由拥有对应状态的权威系统在执行时校验版本和业务约束。若库存由源系统管理，就通过它的原子接口占用，配合幂等、重试和对账。

对于用户编辑与数据源更新，OSv2 公开了两类冲突策略：默认用户编辑优先，或基于时间戳采用较新值。实时同步之外，还需要明确字段归属和冲突规则。[编辑与数据源冲突策略](https://www.palantir.com/docs/foundry/object-edits/how-edits-applied)

## 评论中的关键问题

- 业务关系是否比找到文档本身更重要？一条评论强调，文档属于哪个客户、哪个合同，往往决定搜索结果能否被使用。[相关评论](https://x.com/pirwot/status/2102813190119706697)
- 业务术语有重叠、边界不清时，如何绑定物理数据？这涉及映射维护和建模成本。[相关评论](https://x.com/wileycwj/status/2103014100301451397)
- 上下文工程需要覆盖什么？作者强调数据、逻辑、动作、权限，以及工作流中人的反馈。[作者回复](https://x.com/chadwahl/status/2103103759433814410)
- Agent 与流水线并发写入如何处理？评论提出了这一问题；上文的事务和冲突策略提供了部分公开机制，具体场景还需核对。[并发写入提问](https://x.com/FerBarroso95/status/2103114657196032247)
- 事实和关系过期后如何更新？这是持续维护业务世界模型的问题。[信息过期提问](https://x.com/DivyanshGandhi/status/2103400002081128889)

## 对知识编译的启发

以下为 AI 对本次讨论的推导，留待后续评估：

业务定义、规则、来源映射和动作接口可以编译并版本化；高频业务状态通过增量数据链路维护；Agent 执行动作时校验最新状态。订单每次改变状态，只触发必要的数据更新和派生计算，避免重编译整个知识体系。

编译产物可以进一步考虑实体与关系、事实有效时间、可调用逻辑、动作约束、来源和权限。评估标准是 Agent 因此获得了哪些明确、可验证、可调用的能力。

后续可继续讨论：

- 哪些数据需要物化到对象层，哪些适合执行时查询源系统？
- 如何定义并监测端到端新鲜度的 P95、P99，数据过期时如何处理？
- 多源关联、删除、乱序和重放如何保持正确？
- 哪些变化触发知识重新编译，哪些只更新运行时状态？

相关方法：[LLM Wiki](LLM%20Wiki.md)。本页聚焦企业业务状态与执行系统，可与持续维护知识页的方式对照阅读。

项目应用：[知识编译 / 本体建设](../20-Projects/知识编译/本体建设.md)。
