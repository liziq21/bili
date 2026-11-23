# LLM 映射与源扩展：2026-11 最新证据复核

- **研究日期**：2026-11-23
- **研究状态**：已完成
- **关联分支**：`explore/source-extensibility`
- **前置记录**：[`2026-11-23-source-extensibility-and-ai-mapping.md`](2026-11-23-source-extensibility-and-ai-mapping.md)
- **研究问题**：模型更新频繁，2024–2026 的新论文、官方文档和产业实践是否改变“运行时 AI 做任意源映射不推荐、构建期 AI + 确定性描述符更优”的结论？如果是，bili 的描述符与 PoC 应如何调整？

## 0. 方法与范围

- 通过 arXiv API 执行 25 组检索（schema matching、schema mapping、data integration、structured extraction、JSON schema、constrained decoding、function calling、API integration、program synthesis、entity matching、ETL、data pipeline、wrapper generation、API synthesis、structured output、small language model、on-device、data cleaning、schema evolution、source-to-target、data harmonization、FHIR、EDI 等），按提交时间倒序取回 375 篇去重论文，再按标题/摘要筛选。
- 精读约 60 篇与“源 → 通用模型”直接相关的论文，覆盖 2023–2026；优先选择有实验、基准、生产部署或明确失败分析的资料。
- 交叉核对官方文档：OpenAI Structured Outputs / Function Calling、Anthropic Structured Outputs / Tool Use、Gemini Structured Outputs、vLLM Structured Outputs、Outlines、XGrammar、Ollama、MCP、JSON Schema、OpenAPI 3.1。
- 交叉核对产业资料：Fivetran、Airbyte、MuleSoft、AWS Glue、Databricks、Microsoft Fabric、Google Dataflow、dbt。
- 所有外部资料访问日期均为 **2026-11-23**。arXiv 论文多为预印本，部分已标注会议接收；产业文档含营销内容，本文只采用其中可验证的技术描述。
- 排除：纯医学抽取、与映射无关的通用 RAG、只有营销口号没有技术细节的页面、重复报道、无法验证的二手总结。

## 1. 结论（更新版）

1. **运行时用生成式 AI 把任意源 API 转成通用模型，仍然不推荐用于生产。** 2026 年的新证据比 2024–2025 年更强：约束解码可以保证 JSON 结构合法，但不能保证语义正确；小模型在强 schema 下甚至会出现“越约束越错”。
2. **构建期 AI + 确定性执行，是学术与产业共同收敛的方向。** LLM 负责生成/修复描述符、映射规则或可执行程序，CI 用 fixture 和任务级测试验收；运行时零模型调用。
3. **“schema 合法”不等于“任务正确”。** 必须同时测字段精确值（ID、URL、计数、时长、时间）、分页、去重和失败行为；只看 JSON 解析成功率会系统性高估质量。
4. **窄任务运行时 AI 仍有空间，但必须加约束、校验和回退。** 对分类、标签、语义消歧等窄任务，SLM/decision model + guided decoding + validator + fallback 可以工作；对任意 feed 映射、ID/URL/计数生成，不应交给运行时模型。
5. **源扩展的真正瓶颈不是字段映射，而是 transport/auth/pagination/schema evolution。** API 调用代码生成、接口漂移、签名/WBI、continuation token、媒体流和错误 envelope 才是长期维护成本；描述符应覆盖或明确避开这些部分。
6. **模型更新越快，越需要模型无关的工件与评估协议。** 描述符不应绑定模型；构建期生成要记录模型、prompt 版本、日期、fixture 哈希；每季度用固定评测集复核，而不是追逐模型名。
7. **产业界正在把“声明式管道 + AI 辅助编写 + 人类审核”产品化。** AWS Glue、Databricks、Microsoft Fabric、MuleSoft、Airbyte、Fivetran 的公开资料都指向同一方向：AI 生成/修改管道，平台执行，人审查，治理与审计跟上。

## 2. 证据地图

### 2.1 结构化输出：能力、边界与失败模式

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [OpenAI Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs) | 访问 2026-11-23 | 支持 JSON Schema、`strict`、拒绝/不完整响应处理；限制包括最多 5000 个对象属性、10 层嵌套、120k 字符、1000 个 enum；所有字段必须 `required`、对象必须 `additionalProperties: false`；部分约束（`minLength`、`maxLength`、`pattern`、`format`、`minimum`、`maximum`、`multipleOf`、`minItems`、`maxItems`）在 strict 模式下不支持；首次 schema 有额外延迟，之后缓存。 | 结构化输出是商品能力，但 schema 子集有限；不能把业务校验寄托在模型端。 |
| [Anthropic Structured Outputs](https://docs.anthropic.com/en/docs/build-with-claude/structured-outputs) | 访问 2026-11-23 | 通过 constrained decoding 保证 schema；grammar 首次编译有延迟，缓存 24 小时；schema 结构或工具集变化会使缓存失效；拒绝（refusal）时输出可能不匹配 schema；属性顺序可能被重排。 | 即使“保证 schema”，也有 refusal 和顺序问题；客户端仍需校验与重试策略。 |
| [Gemini Structured Outputs](https://ai.google.dev/gemini-api/docs/structured-output) | 访问 2026-11-23 | 明确提示：输出语法正确 JSON，但必须在应用中校验值；要实现 schema-compliant 但语义错误输出的错误处理；`minLength`、`maxLength`、`minProperties`、`maxProperties`、`uniqueItems`、`contains` 等不被约束解码引擎强制执行，会被剥离或忽略。 | “JSON 合法”与“值正确”分离；必须在应用层做精确值校验。 |
| [vLLM Structured Outputs](https://docs.vllm.ai/en/latest/features/structured_outputs.html) | 访问 2026-11-23 | 支持 JSON schema、regex、choice、grammar；不同后端（xgrammar、guidance、lm-format-enforcer）对 regex 语法和允许 token 的处理不同，切换后端会改变生成结果。 | 自托管/端上方案可复现性依赖后端版本，需固定并测试。 |
| [Outlines](https://dottxt-ai.github.io/outlines/latest/) / [XGrammar](https://github.com/mlc-ai/xgrammar) / [Ollama Structured Outputs](https://ollama.com/blog/structured-outputs) | 访问 2026-11-23 | 结构化生成已覆盖 JSON、regex、CFG；XGrammar 宣称 JSON 生成接近零开销；Ollama 通过 `format` 参数支持 JSON schema。 | 运行时约束解码已不是瓶颈；瓶颈在语义正确性、成本和可维护性。 |
| [JSONSchemaBench](https://arxiv.org/abs/2501.10868) | 2025-01-18 | 10K 个真实 JSON schema，评估 6 个约束解码框架的效率、约束覆盖和输出质量。 | 约束解码框架差异真实存在；不能假设“换个后端结果一样”。 |
| [The Constraint Tax](https://arxiv.org/abs/2605.26128) | 2026-05-20 | 15,000 次生成，Qwen2.5-0.5B/1.5B、SmolLM2-1.7B；硬 schema 把 schema validity 从 61.5% 提到 100%，但 answer accuracy 从 19.7% 降到 11.0%，wrong-valid-schema 从 49.5% 升到 88.9%；日历工具调用任务中，Qwen2.5-1.5B 从 91.5% 可执行准确率降到 48.0%，两种模式 schema validity 都是 100%。 | 强约束可能把错误“包装成合法 JSON”；小模型尤其危险。不要用 schema validity 作为唯一指标。 |
| [Schema-Validated LLM Workflows](https://arxiv.org/abs/2611.27106) | 2026-11-20 | 5 个业务任务、6 种 Python 实现；总体 schema validity 0.684，平均自动质量 0.638；schema-valid 行仍产生大量 task-score flags；PydanticAI/LangGraph/DSPy 接近满分 validity 且质量 0.91–0.94，纯 SDK/Agno/CrewAI 明显更低。 | 框架/绑定路径会显著影响结果；必须测任务质量，而不是只看“能解析”。 |
| [Why Does Structured Output Fail?](https://arxiv.org/abs/2610.33949) | 2026-10-24 | 3,997 次生成、9 个 OpenAI/Anthropic 配置；Markdown fenced JSON 是最常见失败，681 个 fenced 失败中只有 48.0% 去围栏后通过校验，其余还隐藏字段长度等违规。 | 失败是组合型的；简单“去 Markdown 再重试”不够，需细粒度失败分类。 |
| [LLMStructBench](https://arxiv.org/abs/2602.14743) | 2026-02-16 | 22 个模型、5 种 prompting 策略； prompting 策略比模型大小更重要；提升结构合法性往往增加语义错误。 | 对构建期生成，prompt/示例/校验策略比“换更大模型”更关键。 |
| [Constrained Decoding Eliminates Structural Failures...](https://arxiv.org/abs/2609.23742) | 2026-09-20 | 0.6B–4B 模型、14 个结构化任务、native/Outlines/XGrammar；约束解码把 schema validity 从 78.6–92.9% 提到 100%，但语义差距仍在：类型强制可被救回，指令语义失败（如多步工具调用）不可救。 | 约束解码的边界正好是 schema 边界；schema 之外的任务正确性必须单独验证。 |
| [Structure Tax](https://arxiv.org/abs/2610.12056) | 2026-10-08 | “structure tax”取决于 schema 设计而非结构本身：reasoning-first 字段顺序可匹配或超过自由文本；answer-first 顺序会让小模型大幅下降；reasoning-first 还改善校准。 | 如果未来生成描述符/中间结构，字段顺序应“先推理后答案”，不要先给结论字段。 |
| [“We Need Structured Output”](https://arxiv.org/abs/2404.07362) | 2024-04-10 | 51 位从业者、134 个约束用例；约束既包括低层格式/长度，也包括高层语义/风格/无幻觉。 | 业务约束不止 JSON schema；需要任务级规则和人工审核。 |

**小结**：结构化输出已经标准化，但“schema 合法”只是最低门槛。对 bili，必须保留 `validateFeedMappingDescriptor`、conformance golden 和任务级断言；不要引入“运行时模型生成 JSON，schema 过了就上线”的设计。

### 2.2 Schema matching 与数据集成

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [Schema Matching with LLMs: an Experimental Study](https://arxiv.org/abs/2407.11852) | 2024-07-16 | 只给列名/描述时，上下文太少或太多都会降低质量；新模型更“果断”；LLM 适合 bootstrapping，不适合无人审核。 | 描述符字段应带语义描述；不要指望零上下文自动匹配。 |
| [ReMatch](https://arxiv.org/abs/2403.01567) | 2024-03-03 | 检索增强 LLM，无需训练、无需源数据；在大型真实 schema 上有效。 | 构建期可用检索把候选字段/示例值带入 prompt；运行时不需要。 |
| [Magneto](https://arxiv.org/abs/2412.08194) | 2024-12-11 | SLM 做候选检索 + LLM 重排；自监督生成训练数据；兼顾成本与准确率。 | 混合/级联比“全用大模型”更经济；可用于构建期候选生成。 |
| [KcMF](https://arxiv.org/abs/2410.12480) | 2024-10-16 | 伪代码任务分解 + Dataset/Example as Knowledge + 结果 ensemble；五个 backbone 上 SM/EM 均提升，平均 F1 比非 LLM 高 17.93%。 | 分解、示例、ensemble 是提升可靠性的有效手段；但仍是离线/构建期。 |
| [KG-RAG4SM](https://arxiv.org/abs/2501.08686) | 2025-01-15 | 知识图谱检索 + 重排；MIMIC 上 precision +39.79%、F1 +30.56%；缓解幻觉。 | 领域知识/本体可显著改善语义匹配；bili 可用现有 DTO/字段说明做轻量知识。 |
| [Schemora](https://arxiv.org/abs/2507.14376) | 2025-07-18 | 多阶段推荐 + 元数据增强 + 向量/词法混合检索；MIMIC-OMOP 上 HitRate@5 +7.49%、HitRate@3 +3.75%。 | 候选召回 + 重排是成熟模式；适合构建期生成候选映射。 |
| [LLMATCH](https://arxiv.org/abs/2507.10897) | 2025-07-15 | 把 schema matching 拆成 schema preparation、table candidate selection、column alignment；引入 SchemaNet 多表企业 benchmark。 | 复杂源应分阶段处理；bili 的 feed 映射是简化版 column alignment。 |
| [ConStruM](https://arxiv.org/abs/2601.20482) | 2026-01-28 | 结构化上下文打包；HRS-B/PSID-B 平均组合准确率 95.4%，无上下文 LLM 51.6%；在 MIMIC-OMOP/Synthea-OMOP 上附加到 Matchmaker 无统计显著提升。 | 上下文选择很关键，但不是万能；对简单 feed 不必过度工程。 |
| [SemStruct](https://arxiv.org/abs/2605.30729) | 2026-05-29 | 冻结 PLM + GNN 建模列/值/行结构；Valentine、SOTAB-SM 上 SOTA；无需微调 LLM。 | 结构化信息（行共现）比单纯列名更有信号；未来可用样例值做离线校验。 |
| [Self-Demonstrations for Schema-Ontology Mapping](https://arxiv.org/abs/2609.13776) | 2026-09-12 | 神经符号分解 + 自动生成 pattern-guided demonstrations；RODI 三个最难场景上 F1 提升 25 个百分点。 | 自动生成示例可显著提升构建期映射质量；但需要领域模式与验证。 |
| [SINT-Flow](https://arxiv.org/abs/2607.24492) | 2026-07-27 | 5 个 LLM operator 组成 schema integration workflow；SINT-Bench 10 任务/93 表；实体类型检测 ≥97%、属性检测 81%、schema mapping F1 84%；使用 GPT-5.2 与 Qwen3.6-27B；自一致 + review loop 有增益。 | 端到端 schema integration 已可达到“可用但非完美”；review loop 是必要组件。 |
| [MaDI-Bench](https://arxiv.org/abs/2606.30371) | 2026-06-29 | 首个端到端关系表数据集成 benchmark，覆盖 schema matching、值归一化、blocking、entity matching、data fusion；提供任务变体缓解饱和。 | 单一字段映射 benchmark 不足；bili 需要自己的端到端 feed 契约。 |
| [Automatic End-to-End Data Integration using LLMs](https://arxiv.org/abs/2603.10547) | 2026-03-11 | GPT-5.2 生成 schema mappings、值映射、entity matching 训练数据、fusion 验证数据；三个案例中与人类设计管道相当，部分更好；约 $10/案例。 | 构建期“生成整个适配层”在经济上已可行；但仍需测试与人工审核。 |
| [LoStBench](https://arxiv.org/abs/2611.10242) | 2026-11-06 | 纵向研究数据集成；长文本问题比短列名更重要；现有 schema matching 算法在此类 workload 上有限。 | 不同源类型的信号不同；不能把一种描述符策略套到所有源。 |
| [Can LLMs Clean Up Your Mess?](https://arxiv.org/abs/2601.17058) | 2026-01-22 | 系统综述：数据准备从规则/专用模型转向 prompt/context/agentic 工作流；任务分为 cleaning、integration、enrichment。 | 映射只是数据准备的一环；源扩展要同时考虑清洗、标准化、增强。 |
| [Empowering Tabular Data Preparation with Language Models](https://arxiv.org/abs/2508.01556) | 2025-08-03 | 按 acquisition、integration、cleaning、transformation 四阶段分析 LM 的组合方式。 | 描述符应明确属于 integration/transformation 的哪一段，避免职责膨胀。 |

**小结**：LLM 在 schema matching 上确实有效，但最佳实践是检索/上下文打包/混合模型/多阶段/人工审核，而不是单次 prompt。对 bili 的简单 feed，声明式字段映射足够；对语义模糊的源，构建期 LLM 只应产出候选，必须由 fixture 与人工确认。

### 2.3 编译为程序 / 声明式管道

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [Synthesizing JSON Schema Transformers](https://arxiv.org/abs/2405.17681) | 2024-05-27 | 类型驱动程序合成，从输入 JSON Schema 到目标 JSON Schema，使用受约束 rewrite 规则，再生成可执行转换程序。 | 与我们的“描述符 → 确定性执行”同构；可借鉴 rewrite 安全约束。 |
| [Compound Schema Registry](https://arxiv.org/abs/2406.11227) | 2024-06-17 | LLM 解释 schema 变更语义，生成 Schema Transformation Language（STL）中间表示，再由平台执行。 | 描述符可作为 IR；schema evolution 应显式建模。 |
| [SQLMorpher](https://arxiv.org/abs/2309.01957) | 2023-09-05 | LLM 生成 SQL 做数据转换；105 个建筑能耗转换问题达 96% 准确率；迭代 prompt 优化。 | 构建期生成可执行转换是可行路径；需领域知识与 flaw detection。 |
| [TabulaX](https://arxiv.org/abs/2411.17110) | 2024-11-26 | 先分类列转换类型，再生成人类可解释的公式/代码；支持更广转换类别。 | 字段映射可按类型分派 transform；可解释性有利于 review。 |
| [TabClean](https://arxiv.org/abs/2606.25388) | 2026-06-24 | 把 LLM 推理编译成可复用的 guarded cleaning programs；小标注集 + 证据剖析 + 候选验证；六个 benchmark 高精度，显著降低重复运行时/API 成本。 | 最直接支持“LLM 构建期生成、运行时执行确定性程序”；可作为未来数据清洗/映射的模板。 |
| [SCRIBES](https://arxiv.org/abs/2510.01832) | 2025-10-02 | 为结构相似网页生成可复用抽取脚本；脚本质量 +13%，下游 QA +4%。 | 同一源的多页/多 feed 应复用脚本/描述符，而不是每页调用模型。 |
| [DataFlow](https://arxiv.org/abs/2512.16676) | 2025-12-18 | 近 200 个可复用 operator；NL → 可执行 pipeline；Text-to-SQL +3%、代码 +7%。 | 声明式/算子化管道比自由脚本更可维护；bili 的 transform registry 是同类思路。 |
| [DataFlow-Harness](https://arxiv.org/abs/2607.16617) | 2026-07-18 | 平台原生 DAG + typed incremental mutations；12 个数据工程任务 93.3% 端到端通过；相对 Vanilla Claude Code 成本 -72.5%、延迟 -49.9%。 | 让 agent 操作“平台工件”而不是自由脚本，可靠性和成本都更好。 |
| [SemPipes](https://arxiv.org/abs/2602.05134) | 2026-02-04 | 声明式 semantic operators + 运行时按数据/指令/上下文合成实现 + 进化搜索优化。 | 描述符/算子可声明意图，运行时选择确定性实现；适合构建期优化。 |
| [Operation-R1](https://arxiv.org/abs/2602.22721) | 2026-02-26 | 训练轻量 LLM 单步生成数据准备 pipeline；比多步 baseline +8.83/+4.44 个百分点，79% 表压缩，2.2× 成本下降。 | 单步生成 + 运行时保护（operation merge、adaptive rollback）可降本；但仍需验证。 |
| [CRAFT](https://arxiv.org/abs/2607.22642) | 2026-06-24 | schema-stripped PLAN SFT + execution-shaped RL；企业分析场景 Agent Score +9.6 pp、一致性 +4.1 pp；减少 prompt 中塞满 schema。 | 把 schema 知识放进训练/工件，而不是每次 prompt；与“描述符外置”一致。 |
| [LLM4MTLs](https://arxiv.org/abs/2606.25193) | 2026-06-23 | few-shot 提升四种模型转换语言的语法质量，但语义正确性提升不均；语法 prompting 单独使用可能无效。 | 生成转换代码时，语法通过不等于语义正确；必须执行测试。 |
| [Formally Verified Code Synthesis](https://arxiv.org/abs/2606.20776) | 2026-06-18 | LLM 进化式代码合成 + 形式验证，保证输出满足目标 schema；医疗 IoT JSON → FHIR 案例。 | 最高保障级别是“生成 + 形式验证”；至少应做到 fixture 等价测试。 |
| [Mapping Smarter, Not Harder](https://arxiv.org/abs/2510.14900) | 2025-10-16 | 测试时 RL agent + 网络检索；Microsoft Defender 日志映射准确率 56.4% → 72.73%（RAG）→ 93.94%（100 轮）；低置信度人工 review 减少 85%。 | 对缺失文档的源，构建/运维期 agent + 证据检索有效；仍需置信度与人工兜底。 |
| [Dataforge](https://arxiv.org/abs/2511.06185) | 2025-11-09 | LLM agent 做表格数据工程，预算化反馈循环 + 自动停止；下游性能最佳。 | 构建期 agent 应有预算、停止条件和可验证目标。 |

**小结**：2026 年的主流不是“运行时模型直接输出映射”，而是“LLM 生成可执行程序/描述符/管道，平台执行，测试验证”。这与我们 PoC 的方向一致；下一步应补 provenance、drift 检测和任务级断言。

### 2.4 API / 工具集成

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [WAPIIBench](https://arxiv.org/abs/2509.20172) | 2025-09-24 | 评估 LLM 生成 Web API 调用代码；开源模型无一解决超过 40% 任务；常见错误是幻觉 endpoint、参数错误。 | 让模型直接写 API 调用不可靠；描述符/适配器 + 校验更稳。 |
| [Mitigating Errors in LLM-Generated Web API Invocations](https://arxiv.org/abs/2607.05936) | 2026-07-07 | RAG 在 endpoint 未知时减少幻觉，但在 endpoint 已给定时可能生成多余参数；constrained decoding 可靠阻止非法 URL/HTTP 方法/参数，两者互补。 | 约束解码适合 API 调用形状；RAG 适合发现 endpoint；仍要业务校验。 |
| [DADL](https://arxiv.org/abs/2605.05247) | 2026-05-04 | YAML 声明 REST API 的 endpoint、认证、分页、响应整形、访问分类；单一 runtime 执行，无需每 API 一个 server；1,833 个工具/20 个服务；Code Mode 固定上下文成本。 | 与“源描述符”最接近的产业级设计；bili 可借鉴分页/响应整形/固定上下文，但签名源仍用 Dart adapter。 |
| [API synthesis using LLMs](https://arxiv.org/abs/2502.15246) / [APRIL](https://arxiv.org/abs/2509.25196) | 2025-02-21 / 2025-08-29 | LLM 做组件式 API 合成，133/135 任务；APRIL 用自动 prompt 优化 + RLVR 提升功能正确性。 | 构建期生成 API 适配代码可行；需可验证奖励/测试。 |
| [APITestGenie](https://arxiv.org/abs/2604.02039) | 2026-04-02 | 从需求 + OpenAPI 生成 API 集成测试；10 个真实 API、约 1000 个 endpoint；89% 需求在 ≤3 次尝试内生成有效测试。 | 用 OpenAPI + 测试生成做适配层验收，比让模型直接上线更稳。 |
| [Octopus](https://arxiv.org/abs/2404.01549) | 2024-04-02 | 2B/3B/7B 模型在软件 API 文档上微调 + conditional masking；在软件 API 调用上优于 GPT-4。 | 窄任务专用小模型可超过通用大模型；但需要训练数据和约束。 |
| [OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling) | 访问 2026-11-23 | strict mode 要求 `additionalProperties: false`、所有字段 `required`；支持 `tool_search` 延迟加载大量工具（GPT-5.4+）；schema 首次处理有延迟并缓存。 | 工具多时上下文成本是现实问题；描述符/工具目录要能按需检索。 |
| [MCP Specification](https://modelcontextprotocol.io/specification/2025-06-18) | 2025-06-18 | 标准化 LLM 应用与外部数据源/工具的连接；定义 tools/resources/prompts 等。 | MCP 是工具接口标准，不等于数据映射描述符；可作为未来源接入的传输层。 |
| [MuleSoft Vibes](https://www.mulesoft.com/platform/ai/vibes) | 访问 2026-11-23 | 生成式 AI 辅助 API spec、DataWeave 转换和文档生成。 | 产业界把“转换代码生成”放在构建期 IDE，而不是运行时逐条数据。 |
| [Airbyte Chat with Schema](https://airbyte.com/blog/chat-with-schema) | 2026-01-12 | 用 AI 助手理解庞大、文档不全的 API schema，帮助选择需要的流/字段，避免“全量同步”。 | 源 schema 很大时，AI 适合做“选择/裁剪”，不适合逐条映射。 |

**小结**：API 集成代码生成仍不可靠零样本上线；声明式 API 描述（DADL）、OpenAPI 驱动测试（APITestGenie）、约束解码（RAG+CD）是更现实的组合。bili 的描述符目前只覆盖 item 映射；若要覆盖更多源，应明确 transport/auth/pagination 的边界，签名/WBI 继续用 Dart adapter。

### 2.5 Entity matching、数据清洗与成本

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [When Do LLMs Actually Help?](https://arxiv.org/abs/2608.18158) | 2026-08-13 | Abt-Buy 上规则 baseline F1 0.950，LLM zero-shot 0.948；小样本 few-shot 调优后全量降到 0.914；品牌误标任务 LLM 0.833 vs 规则 0.721；重复 5 次自一致 99.7%，多数投票只 +0.005 但成本 5×。 | 有强词法信号时，LLM 不一定优于规则；小样本 prompt 评估会误导；多数投票不划算。 |
| [Entity Matching using Decision Models](https://arxiv.org/abs/2610.34626) | 2026-10-25 | 6 个 decision model 零样本、8 个 benchmark；最佳 decision model 平均 F1 超过 Ditto，仅比 frontier LLM 低几个点，成本 <1%；模型级联再提升 2.7–4.8 个点，成本降 2.5–5.1×。 | 窄匹配任务可用 decision model/级联，而不是每次调用大 LLM。 |
| [Beyond Scale and Generation](https://arxiv.org/abs/2607.24688) | 2026-07-27 | 控制 matcher 架构、模型变体、模型大小、9 个数据集、1,215 次微调；bi-encoder 的模型变体很关键；cross-encoder 稳定优于 bi-encoder；生成式 matcher 的优势集中在分布偏移；大模型更依赖 shortcut。 | “换大模型”不必然更好；架构与数据分布更重要。 |
| [CaRL-EM](https://arxiv.org/abs/2609.01195) | 2026-09-01 | 成本感知 RL 控制器在 Match/Compare/Select/Decide 与不同模型容量间调度；7 个 benchmark 上质量-成本权衡优于强 baseline。 | 运行时可用“路由/级联”而非单一模型；但控制器本身需要训练与评估。 |
| [BEACON](https://arxiv.org/abs/2603.11391) | 2026-03-12 | 预算感知的跨域 entity matching；利用候选对嵌入选择 out-of-domain 样本。 | 低资源场景可用跨域迁移；仍需标签预算管理。 |
| [Structured Multi-Step Reasoning for EM](https://arxiv.org/abs/2511.22832) | 2025-11-28 | 三步分解（匹配/不匹配 token、关键属性、最终判断）+ debate；部分数据集提升，但仍有挑战。 | 分解推理对语义匹配有帮助；但不是稳定万能。 |
| [LLM4MEM](https://arxiv.org/abs/2604.21238) | 2026-04-23 | 多表 entity matching；属性协调 + 传递共识嵌入 + 密度剪枝；6 个数据集平均 F1 +5.1%。 | 多源/多表匹配需要候选剪枝与一致性；不能只靠 pairwise prompt。 |
| [Heterogeneity in Entity Matching](https://arxiv.org/abs/2508.08076) | 2025-08-11 | 综述 representation/semantic heterogeneity；指出 human-in-the-loop、多模态、KG/LLM 结合与公平评估方向。 | 源异构是结构性问题；描述符要能表达语义差异，不能只做字符串映射。 |
| [Agentic Data Cleaning Without a Clean Reference](https://arxiv.org/abs/2608.14765) | 2026-08-14 | 合成损坏 + 真实数据描述分析，126 次运行；确定性 profiling baseline 检测 F1 0.561，最佳 LLM 配置 0.421；没有配置在所有指标上最好；保守配置没有不安全修改，但也没有直接修复。 | 数据清洗中规则/剖析基线经常被低估；LLM 不是默认更优。 |
| [LasRepair](https://arxiv.org/abs/2606.17582) | 2026-06-16 | LLM 作为 instructor 选择全局修复上下文，SLM 作为 corrector；EM 迭代优化上下文，列校准置信度降权不可靠修复。 | 大模型规划 + 小模型执行是可行降本模式；仍需置信度校准。 |
| [Cost-Efficient RAG for EM](https://arxiv.org/abs/2602.05708) | 2026-02-05 | blocking-based batch retrieval + generation；9 个 EM 数据集上质量可比/更好，端到端开销显著降低。 | 批量/分块比逐对 RAG 更经济；运行时 AI 也应先做候选裁剪。 |
| [OpenSanctions Pairs](https://arxiv.org/abs/2603.11051) | 2026-02-24 | 大规模 entity matching 与 LLM 的 benchmark/分析。 | 大规模匹配需要专门的候选生成与成本控制。 |

**小结**：entity matching 是 LLM 的强项，但“规则/decision model 先做、LLM 只处理疑难”通常更经济。对 bili，视频/用户 ID 匹配应确定性；只有语义标签、分类、模糊标题归一化才考虑离线模型。

### 2.6 人类审核、审计与漂移

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [BDIViz](https://arxiv.org/abs/2507.16117) / [BDIViz in Action](https://arxiv.org/abs/2604.10763) | 2025-07-22 / 2026-04-12 | 交互式 schema matching 可视化 + LLM 解释；用户在 heatmap 中验证候选，查看属性描述、样例值、分布。 | 映射结果需要可解释的 review 界面；CI golden 是自动化版本。 |
| [ExtracTable](https://arxiv.org/abs/2506.03221) | 2025-06-03 | human-in-the-loop + 用户 schema + LLM 抽取；SUS 84.17；从 4 小时–2 周降到平均 24 分钟；但人工验证仍必要。 | 人类审核不是形式；它能显著提升可用性。 |
| [Interactive Data Harmonization with LLM Agents](https://arxiv.org/abs/2502.07132) | 2025-02-10 | Harmonia 结合 LLM 推理、交互 UI、数据协调原语，合成可复用 pipeline。 | 源接入应是“生成候选 pipeline + 人确认”，不是全自动。 |
| [Conflicted Records](https://arxiv.org/abs/2610.29669) | 2026-10-21 | 类型化对抗契约 + 三模型 quorum + 引用/语义 invariant；提供审计轨迹，区分真实修复与 blanket suppression。 | 如果引入 AI 输出，必须有可审计的契约和独立校验。 |
| [“Will This Data Break My Task?”](https://arxiv.org/abs/2608.09376) | 2026-08-10 | 联合分析数据与下游任务代码，合成 task-aware data unit tests；维护 data-code assumption graph。 | 任务级测试应链接到消费代码，而不只是数据 schema。 |
| [SchemaShield-Lite](https://arxiv.org/abs/2610.23342) | 2026-10-16 | 接口漂移下，schema 校验 + 候选集重试 + 一次性约束修复；Qwen3.5-9B 上 DICE-300 0.717→0.813、BFCL-200 0.580→0.805；候选集漂移（干扰工具）伤害最大。 | 源/工具目录变化是主要风险；描述符要有 drift 检测与候选集管理。 |
| [AegisFlow](https://arxiv.org/abs/2610.06971) | 2026-10-03 | 多 agent 自愈数据管道；JSON schema 变化 96%、标点漂移 98%、Shadow DOM 85% 成功；patch 成功率 92%；MTTR 170 分钟→3.2 分钟。 | 自动修复适合“生成 PR + 测试”，不适合运行时静默改映射。 |
| [EvoSchema](https://arxiv.org/abs/2603.10697) | 2026-03-11 | schema evolution 10 类扰动；表级扰动比列级影响更大；训练时引入 schema 变化可提升鲁棒性。 | 描述符要版本化；表/结构变化要触发 conformance。 |
| [Databricks Genie ZeroOps](https://www.databricks.com/blog/genie-zeroops-now-public-beta-autonomous-agent-fixes-data-pipelines-lessons-80000-customer) | 访问 2026-11-23 | 从 80,000+ 客户管道问题学习；检测、调查、修复上游 schema 变化/数据质量异常；一键 PR。 | 产业界把“修复”落到 PR，而不是运行时自动改数据。 |
| [Microsoft Fabric Copilot](https://learn.microsoft.com/en-us/fabric/data-factory/copilot-fabric-data-factory) | 访问 2026-11-23 | 自然语言生成 Dataflow Gen2 查询/转换；明确限制：AI 生成查询可能不准确，必须 review；预览只显示样本数据，成功预览不代表全量正确；Copilot 可未经批准做部分修改。 | 官方产品自己承认“生成成功 ≠ 全量正确”；bili 更应坚持测试门禁。 |
| [Fivetran: Automated Schema Migration](https://www.fivetran.com/blog/automated-schema-migration) | 2020-06-11 | schema 变化会中断传统 ETL；自动化集成/ELT 减少重建。 | schema drift 是长期问题，不是新问题；描述符需要 drift 测试。 |

**小结**：人类审核、审计轨迹、任务级测试和 drift 检测是生产化的必要条件。bili 的 conformance golden 是正确方向；下一步应加 fixture/schema 哈希和定期刷新。

### 2.7 安全与凭据

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [API Secrets Should Never Become Tokens...](https://arxiv.org/abs/2609.33371) | 2026-09-27 | API key 进入 prompt/日志/记忆/生成代码/错误 payload 后会扩散；提出 vault-mediated execution，模型只选 connector ID，可信边界注入凭据；16 项黑盒实验通过；也报告了配置错误导致认证失败的负结果。 | 运行时 AI 不应接触凭据；bili 是只读客户端，也不应把 token 放进 prompt。 |
| [Kerkoporta](https://arxiv.org/abs/2611.00138) | 2026-10-29 | 结构化输出后门：触发器让 agent 发出攻击者选择的 tool call；最高 96.2% 成功率； poisoned 模型甚至能在 utility benchmark 上超过 clean baseline。 | 不能因为模型“更准”就信任其 tool call；必须有 allowlist/validator/人工审核。 |
| [SecAlign](https://arxiv.org/abs/2410.05451) | 2024-10-07 | 偏好优化防御 prompt injection，将多种攻击成功率降到 <10%，但非零；保持相近 utility。 | 源数据是 untrusted input；运行时模型读取第三方 API 数据会增加注入面。 |
| [MCP Specification](https://modelcontextprotocol.io/specification/2025-06-18) | 2025-06-18 | 规范包含安全与信任章节；工具/资源由外部 server 提供。 | 若未来接入 MCP，需把 server 视为不可信边界。 |

**小结**：安全是运行时 AI 的额外维护面；构建期生成 + 运行时确定性执行天然避开大部分凭据/注入风险。若未来引入运行时窄模型，必须做到凭据隔离、输出校验、工具 allowlist。

### 2.8 产业产品化

| 来源 | 日期 | 关键证据 | 对 bili 的含义 |
|---|---|---|---|
| [Fivetran: What is data mapping?](https://www.fivetran.com/learn/data-mapping) | 2025-09-03 | 数据映射是跨系统字段对齐；强调一致性、完整性、合规。 | 映射是基础能力，但需要治理与验证。 |
| [Fivetran: Using LLMs to auto-categorize your data](https://www.fivetran.com/blog/using-llms-to-auto-categorize-your-data) | 2025-04-07 | AI Columns 用 LLM 做分类/标签；强调 prompt 的结构与上下文。 | LLM 更适合“分类/标签”，不是精确 ID/URL 映射。 |
| [Fivetran: Agents Schema](https://www.fivetran.com/blog/how-agents-schema-brings-trusted-business-context-to-ai) | 2026-06-29 | 为 AI agent 提供可移植、可治理、可复用的业务上下文/语义层。 | 语义层/描述符是 AI 时代的基础设施，不只是 ETL 配置。 |
| [Airbyte: AI Connectors](https://airbyte.com/agentic-data/ai-connector) | 2026-01-16（更新 2026-09-08） | AI connector 统一 OAuth、token refresh、数据归一化、权限；减少每源自定义集成。 | 连接器的价值在认证/归一化/治理，不只是字段映射。 |
| [Airbyte: Chat with Schema](https://airbyte.com/blog/chat-with-schema) | 2026-01-12（更新 2026-06-29） | 大 schema/文档不全时，用 AI 助手选择需要的流/字段，避免全量同步。 | AI 适合“选择/裁剪”，不适合逐条映射。 |
| [Airbyte: No-Code Connector Builder](https://airbyte.com/blog/launching-the-no-code-connector-builder-build-custom-connectors-in-minutes) | 2023-05-18（更新 2026-06-29） | 声明式/低代码构建 API connector，15 分钟级；100+ connector 投产。 | 声明式 connector 已被验证；bili 的描述符是同类思路的简化版。 |
| [MuleSoft Vibes](https://www.mulesoft.com/platform/ai/vibes) | 访问 2026-11-23 | 生成式 AI 辅助 API spec、DataWeave 转换、文档。 | 产业界把 AI 放在开发期，不是运行时逐条数据。 |
| [AWS Glue](https://aws.amazon.com/glue/) | 访问 2026-11-23 | Spark Declarative Pipelines 声明式编排；生成式 AI 辅助代码生成；AI 驱动的 Spark job modernization。 | “声明式 + AI 辅助编写”是主流产品方向。 |
| [Databricks Spark Declarative Pipelines](https://www.databricks.com/product/data-engineering/spark-declarative-pipelines) | 访问 2026-11-23 | agent 声明目标数据结果，SDP 解析依赖、dry run、执行质量规则；Genie Code 支持自然语言授权。 | 声明式目标 + 平台执行 + 质量规则，与 bili descriptor + conformance 同构。 |
| [Databricks Genie ZeroOps](https://www.databricks.com/blog/genie-zeroops-now-public-beta-autonomous-agent-fixes-data-pipelines-lessons-80000-customer) | 访问 2026-11-23 | 自主检测/调查/修复管道问题；一键 PR；基于 80k+ 客户问题。 | 自动修复的产物是 PR，不是运行时静默改映射。 |
| [Microsoft Fabric Copilot](https://learn.microsoft.com/en-us/fabric/data-factory/copilot-fabric-data-factory) | 访问 2026-11-23 | NL → Dataflow Gen2；AI 生成查询/解释/图表可能不准确；预览只采样；需 review。 | 官方产品也要求人工审核；bili 的 CI 门禁应更严格。 |
| [Google Dataflow](https://cloud.google.com/dataflow) | 访问 2026-11-23 | 流式 AI/ML；Gemini/Gemma 远程推理；MLTransform。 | 运行时 AI 更适合作为流处理算子，而不是通用映射器。 |
| [dbt blog corpus](https://www.getdbt.com/llms-full-blog.txt) | 访问 2026-11-23 | 2026 内容提到 MCP 集成、Semantic Layer、AI 成熟度；ELT 中 schema mapping 变更仍是维护负担。 | 语义层/MCP 是上下文接口；映射仍需工程化治理。 |

**小结**：产业界的共同模式是“声明式/低代码工件 + AI 辅助生成 + 平台执行 + 治理/审核”。没有主流厂商把“运行时 LLM 逐条数据生成映射”作为默认架构。

## 3. 对原结论的修正与加强

### 3.1 加强

- **运行时生成式 AI 做任意源映射仍不推荐。** 新增的 Constraint Tax、Schema-Validated LLM Workflows、LLMStructBench、When Do LLMs Actually Help、Agentic Data Cleaning 都提供了更强的反例。
- **构建期 AI + 确定性执行仍是更优解。** AI-assisted JSON Schema Creation、TabClean、SCRIBES、DataFlow、SemPipes、MuleSoft/Airbyte/Fabric/Databricks 都指向同一模式。
- **schema 合法 ≠ 任务正确。** 这是本次复核最重要的新增结论；原记录已有此意，但 2026 年证据更具体、更量化。

### 3.2 修正/细化

- **窄任务运行时 AI 不是完全否定。** 对分类、标签、语义消歧，SLM/decision model + guided decoding + validator + fallback 可以工作；但必须用任务级指标评估，且不能用于 ID/URL/计数。
- **约束解码可能伤害小模型语义。** 原记录把 constrained decoding 视为“结构保障”；新证据显示它可能把错误包装成合法 JSON（Constraint Tax）。因此“结构约束”必须与“语义校验”分开。
- **schema 设计会影响推理。** reasoning-first 字段顺序可匹配/超过自由文本；answer-first 会伤害小模型。未来生成中间结构时应遵循。
- **源描述符不应只覆盖字段映射。** DADL、Databricks SDP、AWS Glue、Airbyte 都说明 transport/auth/pagination/response shaping/治理是描述符的一部分；bili 当前 `FeedMappingDescriptor` 只是子集。
- **模型更新需要 provenance 与评估协议。** 2026 年文档/论文中的模型名（GPT-5.2、GPT-6.2、Claude 5.x、Qwen3.x、Llama 3.x、Gemma2、SmolLM2）变化很快；描述符不应绑定模型，生成过程要可追溯。

## 4. 对 bili 的具体建议

### 4.1 保留

- 构建期 LLM + Dart `FeedMappingDescriptor` + `validateFeedMappingDescriptor` + conformance golden。
- `schemaVersion` / `requiredFields`。
- 运行时零模型调用；描述符失败时返回 `Result.error`，不调用 LLM。
- golden 由旧 adapter 生成，避免声明式引擎自证。

### 4.2 下一步（按优先级）

**P0：把“可追溯”和“任务正确”补上**

1. **描述符 provenance**：记录生成模型、prompt 版本、生成日期、fixture 哈希、reviewer。可以先放在 PR 模板/描述符旁注，成熟后再进 `MappingProvenance` 常量。
2. **任务级 conformance**：除结构 diff 外，断言精确 ID、URL、计数、时长、时间、分页和去重；不要只比较 JSON 形状。
3. **fixture/schema drift 检测**：定期刷新 fixture，运行 conformance；源结构变化时 CI 红，构建期 agent 只提 PR，不自动合并。
4. **source schema 哈希**：在描述符或测试中记录源 schema/样例哈希，检测静默漂移。

**P1：把描述符边界说清楚**

5. **区分 `FeedMappingDescriptor` 与 `SourceDescriptor`**：前者只做 item → canonical model；后者才覆盖 endpoint/auth/pagination/envelope/rate limit。签名/WBI/媒体流继续用 Dart adapter，不强行描述符化。
6. **分页扩展**：已有 `hasMorePath` / `totalCountPath`；如遇 continuation token，再增加 `continuationTokenPath`，不要硬编码。
7. **字段语义描述**：给 `FieldMapping` 增加可选 `description`/`examples`，供构建期 LLM 与人工 review 使用；运行时忽略。
8. **描述符编写指南**：reasoning-first 字段顺序、精确值规则、null/缺失处理、失败行为、URL 规范化、计数/时长解析。

**P2：构建期 agent 与运行时窄 AI**

9. **构建期修复 agent**：输入失败 fixture + 现有描述符，输出 diff；必须通过 validator、conformance、任务级测试；开 PR 供人 review，不自动合并。
10. **运行时窄 AI 仅限语义分类**：如标签/分类/模糊标题归一化，使用 decision model/SLM + guided decoding + validator + fallback；不用于 ID/URL/计数/分页。
11. **季度模型评估**：固定 20+ fixture，测 schema validity、字段精确匹配、任务正确率、cost per successful task、p50/p95 latency、reviewer edit rate；只在任务正确率提升且成本可接受时升级模型/prompt。

### 4.3 不要做

- 不要把运行时 LLM 放进 feed 映射主路径。
- 不要让 LLM 生成可执行代码后不经测试/形式验证就上线。
- 不要用 schema validity 作为唯一质量指标。
- 不要把 API key/token 放进 prompt、日志或描述符。
- 不要自动合并 LLM 生成的描述符。
- 不要为了“统一”把签名、WBI、媒体流等复杂源强行描述符化。

## 5. 模型更新观察与评估协议

### 5.1 原则

- **工件模型无关**：描述符、transform、conformance fixture 不依赖具体模型。
- **生成过程可追溯**：记录模型、prompt、日期、fixture 哈希、reviewer；模型升级不改变描述符语义。
- **评估先于升级**：新模型/新 prompt 必须通过同一评测集，不能凭“感觉更聪明”切换。
- **成本纳入指标**：使用 cost per successful task、p50/p95 latency、reviewer edit rate，而不只是准确率。

### 5.2 建议评测集与指标

- 评测集：20+ 真实 fixture，覆盖热门/排行/用户投稿/搜索/直播等不同形状；每个 fixture 有旧 adapter 生成的 canonical golden。
- 指标：
  - schema validity（最低门槛）
  - 字段精确匹配（ID/URL/count/duration/date）
  - 任务正确率（分页、去重、空态、错误 envelope）
  - cost per successful task
  - p50/p95 latency
  - reviewer edit rate（人工修改比例）
- 协议：固定模型版本与 prompt；每个配置跑 3 次；记录方差；与现有确定性描述符对比；只有任务正确率提升且成本可接受才升级。

### 5.3 观察清单

- 官方结构化输出能力与限制：OpenAI、Anthropic、Gemini、vLLM、Outlines、XGrammar、Ollama。
- 模型家族：GPT-6.x、Claude 5.x、Gemini 3/Decision、Qwen3.x、Llama 3.x/4、Gemma 3/4、Mistral、Phi-4、DeepSeek、SmolLM。
- 新论文/基准：MaDI-Bench、SchemaNet、SINT-Bench、LoStBench、LROBench、OurBench、WAPIIBench、JSONSchemaBench、LLMStructBench。
- 触发复核：新模型显著降本/提升结构化输出；新 schema matching benchmark；源 API 漂移；安全/合规变化。

## 6. 验证方式

- 本次为文献与文档复核，未修改运行时代码；上一次 PoC 的验证仍有效：data 23、bilibili 136、app 800、tool 109、test matrix 178/178。
- 文档改动后运行 `git diff --check` 与 `python3 tool/test_matrix.py --check`，确保不破坏仓库门禁。
- 外部资料均为公开链接；未在测试中访问网络。

## 7. 未决问题

- 描述符继续用 Dart 常量，还是迁移到 YAML/JSON 资产以便 LLM/非 Dart 工具生成？
- `SourceDescriptor` 的边界：auth/signing 是否应完全排除在描述符之外？
- 如何为 feed 定义“任务正确率”，而不只是字段 diff？
- fixture 刷新频率与 drift 告警阈值？
- provenance 放在描述符内还是 sidecar 文件？
- 是否引入构建期修复 agent？如何防止自动合并错误描述符？
- 运行时窄 AI 是否有真实用例（标签/分类）？如果有，选 decision model 还是 SLM？
- 采用哪些公开 benchmark 作为外部参照，哪些只做内部 conformance？

## 8. 参考资料

### 8.1 结构化输出与验证

- [OpenAI Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs)（访问 2026-11-23）
- [OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling)（访问 2026-11-23）
- [Anthropic Structured Outputs](https://docs.anthropic.com/en/docs/build-with-claude/structured-outputs)（访问 2026-11-23）
- [Anthropic Tool Use](https://docs.anthropic.com/en/docs/build-with-claude/tool-use/overview)（访问 2026-11-23）
- [Gemini Structured Outputs](https://ai.google.dev/gemini-api/docs/structured-output)（访问 2026-11-23）
- [vLLM Structured Outputs](https://docs.vllm.ai/en/latest/features/structured_outputs.html)（访问 2026-11-23）
- [Outlines](https://dottxt-ai.github.io/outlines/latest/)（访问 2026-11-23）
- [XGrammar](https://github.com/mlc-ai/xgrammar)（访问 2026-11-23）
- [Ollama Structured Outputs](https://ollama.com/blog/structured-outputs)（访问 2026-11-23）
- [JSON Schema](https://json-schema.org/)（访问 2026-11-23）
- [OpenAPI 3.1](https://spec.openapis.org/oas/v3.1.0.html)（访问 2026-11-23）
- [MCP Specification](https://modelcontextprotocol.io/specification/2025-06-18)（2025-06-18）
- [JSONSchemaBench](https://arxiv.org/abs/2501.10868)（2025-01-18）
- [The Constraint Tax](https://arxiv.org/abs/2605.26128)（2026-05-20）
- [Schema-Validated LLM Workflows](https://arxiv.org/abs/2611.27106)（2026-11-20）
- [Why Does Structured Output Fail?](https://arxiv.org/abs/2610.33949)（2026-10-24）
- [LLMStructBench](https://arxiv.org/abs/2602.14743)（2026-02-16）
- [Constrained Decoding Eliminates Structural Failures...](https://arxiv.org/abs/2609.23742)（2026-09-20）
- [Structure Tax](https://arxiv.org/abs/2610.12056)（2026-10-08）
- [“We Need Structured Output”](https://arxiv.org/abs/2404.07362)（2024-04-10）

### 8.2 Schema matching 与数据集成

- [Schema Matching with LLMs: an Experimental Study](https://arxiv.org/abs/2407.11852)（2024-07-16）
- [ReMatch](https://arxiv.org/abs/2403.01567)（2024-03-03）
- [Magneto](https://arxiv.org/abs/2412.08194)（2024-12-11）
- [KcMF](https://arxiv.org/abs/2410.12480)（2024-10-16）
- [KG-RAG4SM](https://arxiv.org/abs/2501.08686)（2025-01-15）
- [Schemora](https://arxiv.org/abs/2507.14376)（2025-07-18）
- [LLMATCH](https://arxiv.org/abs/2507.10897)（2025-07-15）
- [ConStruM](https://arxiv.org/abs/2601.20482)（2026-01-28）
- [SemStruct](https://arxiv.org/abs/2605.30729)（2026-05-29）
- [Self-Demonstrations for Schema-Ontology Mapping](https://arxiv.org/abs/2609.13776)（2026-09-12）
- [PiLLar](https://arxiv.org/abs/2604.26356)（2026-04-29）
- [SINT-Flow](https://arxiv.org/abs/2607.24492)（2026-07-27）
- [MaDI-Bench](https://arxiv.org/abs/2606.30371)（2026-06-29）
- [Automatic End-to-End Data Integration using LLMs](https://arxiv.org/abs/2603.10547)（2026-03-11）
- [LoStBench](https://arxiv.org/abs/2611.10242)（2026-11-06）
- [Can LLMs Clean Up Your Mess?](https://arxiv.org/abs/2601.17058)（2026-01-22）
- [Empowering Tabular Data Preparation with Language Models](https://arxiv.org/abs/2508.01556)（2025-08-03）
- [KGpipe](https://arxiv.org/abs/2511.18364)（2025-11-23）
- [BDIViz](https://arxiv.org/abs/2507.16117)（2025-07-22）
- [BDIViz in Action](https://arxiv.org/abs/2604.10763)（2026-04-12）
- [Interactive Data Harmonization with LLM Agents](https://arxiv.org/abs/2502.07132)（2025-02-10）
- [ExtracTable](https://arxiv.org/abs/2506.03221)（2025-06-03）
- [EcoTable](https://arxiv.org/abs/2606.26613)（2026-06-25）

### 8.3 编译为程序 / 声明式管道

- [Synthesizing JSON Schema Transformers](https://arxiv.org/abs/2405.17681)（2024-05-27）
- [Compound Schema Registry](https://arxiv.org/abs/2406.11227)（2024-06-17）
- [SQLMorpher](https://arxiv.org/abs/2309.01957)（2023-09-05）
- [TabulaX](https://arxiv.org/abs/2411.17110)（2024-11-26）
- [TabClean](https://arxiv.org/abs/2606.25388)（2026-06-24）
- [SCRIBES](https://arxiv.org/abs/2510.01832)（2025-10-02）
- [DataFlow](https://arxiv.org/abs/2512.16676)（2025-12-18）
- [DataFlow-Harness](https://arxiv.org/abs/2607.16617)（2026-07-18）
- [SemPipes](https://arxiv.org/abs/2602.05134)（2026-02-04）
- [Operation-R1](https://arxiv.org/abs/2602.22721)（2026-02-26）
- [CRAFT](https://arxiv.org/abs/2607.22642)（2026-06-24）
- [LLM4MTLs](https://arxiv.org/abs/2606.25193)（2026-06-23）
- [Formally Verified Code Synthesis](https://arxiv.org/abs/2606.20776)（2026-06-18）
- [Mapping Smarter, Not Harder](https://arxiv.org/abs/2510.14900)（2025-10-16）
- [Dataforge](https://arxiv.org/abs/2511.06185)（2025-11-09）

### 8.4 API / 工具集成

- [WAPIIBench](https://arxiv.org/abs/2509.20172)（2025-09-24）
- [Mitigating Errors in LLM-Generated Web API Invocations](https://arxiv.org/abs/2607.05936)（2026-07-07）
- [DADL](https://arxiv.org/abs/2605.05247)（2026-05-04）
- [API synthesis using LLMs](https://arxiv.org/abs/2502.15246)（2025-02-21）
- [APRIL](https://arxiv.org/abs/2509.25196)（2025-08-29）
- [APITestGenie](https://arxiv.org/abs/2604.02039)（2026-04-02）
- [Octopus](https://arxiv.org/abs/2404.01549)（2024-04-02）
- [Robust Function Calling under Interface Drift](https://arxiv.org/abs/2610.23342)（2026-10-16）
- [BAML](https://github.com/boundaryml/baml)（访问 2026-11-23）
- [Instructor](https://python.useinstructor.com/)（访问 2026-11-23）
- [PydanticAI](https://ai.pydantic.dev/)（访问 2026-11-23）
- [LangExtract](https://github.com/google/langextract)（访问 2026-11-23）
- [GLiNER2](https://github.com/fastino-ai/GLiNER2)（访问 2026-11-23）

### 8.5 Entity matching、清洗与成本

- [When Do LLMs Actually Help?](https://arxiv.org/abs/2608.18158)（2026-08-13）
- [Entity Matching using Decision Models](https://arxiv.org/abs/2610.34626)（2026-10-25）
- [Beyond Scale and Generation](https://arxiv.org/abs/2607.24688)（2026-07-27）
- [CaRL-EM](https://arxiv.org/abs/2609.01195)（2026-09-01）
- [BEACON](https://arxiv.org/abs/2603.11391)（2026-03-12）
- [Structured Multi-Step Reasoning for EM](https://arxiv.org/abs/2511.22832)（2025-11-28）
- [LLM4MEM](https://arxiv.org/abs/2604.21238)（2026-04-23）
- [Heterogeneity in Entity Matching](https://arxiv.org/abs/2508.08076)（2025-08-11）
- [Agentic Data Cleaning Without a Clean Reference](https://arxiv.org/abs/2608.14765)（2026-08-14）
- [LasRepair](https://arxiv.org/abs/2606.17582)（2026-06-16）
- [Cost-Efficient RAG for EM](https://arxiv.org/abs/2602.05708)（2026-02-05）
- [OpenSanctions Pairs](https://arxiv.org/abs/2603.11051)（2026-02-24）

### 8.6 人类审核、审计、漂移与安全

- [Conflicted Records](https://arxiv.org/abs/2610.29669)（2026-10-21）
- [“Will This Data Break My Task?”](https://arxiv.org/abs/2608.09376)（2026-08-10）
- [SchemaShield-Lite](https://arxiv.org/abs/2610.23342)（2026-10-16）
- [AegisFlow](https://arxiv.org/abs/2610.06971)（2026-10-03）
- [EvoSchema](https://arxiv.org/abs/2603.10697)（2026-03-11）
- [API Secrets Should Never Become Tokens...](https://arxiv.org/abs/2609.33371)（2026-09-27）
- [Kerkoporta](https://arxiv.org/abs/2611.00138)（2026-10-29）
- [SecAlign](https://arxiv.org/abs/2410.05451)（2024-10-07）
- [RUBICON](https://arxiv.org/abs/2604.21413)（2026-04-23）
- [Schema-Aware Localisation (SAL)](https://arxiv.org/abs/2607.22572)（2026-06-03）

### 8.7 产业与官方文档

- [Fivetran: What is data mapping?](https://www.fivetran.com/learn/data-mapping)（2025-09-03）
- [Fivetran: Using LLMs to auto-categorize your data](https://www.fivetran.com/blog/using-llms-to-auto-categorize-your-data)（2025-04-07）
- [Fivetran: Agents Schema](https://www.fivetran.com/blog/how-agents-schema-brings-trusted-business-context-to-ai)（2026-06-29）
- [Fivetran: Automated Schema Migration](https://www.fivetran.com/blog/automated-schema-migration)（2020-06-11）
- [Airbyte: AI Connectors](https://airbyte.com/agentic-data/ai-connector)（2026-01-16，更新 2026-09-08）
- [Airbyte: Chat with Schema](https://airbyte.com/blog/chat-with-schema)（2026-01-12，更新 2026-06-29）
- [Airbyte: No-Code Connector Builder](https://airbyte.com/blog/launching-the-no-code-connector-builder-build-custom-connectors-in-minutes)（2023-05-18，更新 2026-06-29）
- [MuleSoft Vibes](https://www.mulesoft.com/platform/ai/vibes)（访问 2026-11-23）
- [AWS Glue](https://aws.amazon.com/glue/)（访问 2026-11-23）
- [Databricks Spark Declarative Pipelines](https://www.databricks.com/product/data-engineering/spark-declarative-pipelines)（访问 2026-11-23）
- [Databricks Genie ZeroOps](https://www.databricks.com/blog/genie-zeroops-now-public-beta-autonomous-agent-fixes-data-pipelines-lessons-80000-customer)（访问 2026-11-23）
- [Microsoft Fabric Copilot](https://learn.microsoft.com/en-us/fabric/data-factory/copilot-fabric-data-factory)（访问 2026-11-23）
- [Google Dataflow](https://cloud.google.com/dataflow)（访问 2026-11-23）
- [dbt blog corpus](https://www.getdbt.com/llms-full-blog.txt)（访问 2026-11-23）
