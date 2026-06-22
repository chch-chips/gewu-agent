# 项目亮点与简历表达

## 1. 项目核心价值

Gewu Agent 的简历价值不在于“调用了某个大模型 API”，而在于完整实现了一个 AI 应用平台的关键工程链路：

- 多智能体配置。
- RAG 知识库问答。
- PDF/PPT 文档解析和索引构建。
- 模型路由，支持云模型和本地模型。
- Tool Calling 和 MCP 工具生态接入。
- 自研 ReAct Agent Runtime。
- 检索评测、引用溯源、工具轨迹可观测。

## 2. 可以写进简历的版本

项目名称：Gewu Agent - 基于 Spring AI 的个人智能体与 RAG 知识库平台

项目描述：

基于 Spring Boot、Spring AI、Vue 和向量数据库开发个人智能体平台，支持面试助手、408 考研学习助手和自研 ReAct 智能体 LeManus。系统实现 PDF/PPT 文档解析、文本切分、向量化入库、语义检索、引用溯源、流式问答、工具调用和 MCP 工具接入，支持 DeepSeek 云模型和 Ollama 本地模型切换。

项目亮点：

- 设计并实现 RAG 知识库链路，支持文档上传、解析、切分、embedding、向量检索和带来源引用的问答。
- 封装模型路由层，统一管理云端大模型和本地 Ollama 模型，支持按智能体配置模型参数。
- 自研 LeManus ReAct Runtime，实现 Reason/Act/Observe/Reflect 多步执行循环，并支持工具白名单、最大步数和执行轨迹记录。
- 接入 Spring AI Tool Calling 与 MCP，构建可扩展工具注册表，支持知识库检索、文件摘要等工具能力。
- 建立 RAG 调试与评测机制，对召回片段、引用准确性和回答质量进行可视化分析。

## 3. 面试讲法

### 为什么做这个项目

我不想只停留在调用大模型 API，而是希望完整理解 AI 应用背后的工程链路，所以做了一个个人智能体平台。项目从知识库问答切入，逐步扩展到工具调用、MCP 和自研 ReAct 智能体。

### 技术难点

第一个难点是 RAG 效果控制。不是把文档切一切丢进向量库就结束，还需要考虑切分粒度、元数据、TopK、重排、引用来源和评测。

第二个难点是 Agent 可控性。智能体如果能调用工具，就必须限制工具权限、最大步数、超时和执行日志，否则很难调试和保证安全。

第三个难点是模型抽象。云模型和本地模型能力不同，尤其是 Tool Calling、Embedding 和上下文长度不同，所以需要做模型路由和能力声明。

### 可以深入追问的点

- PDF/PPT 文档如何解析和保留页码/页标题？
- 为什么选择 PostgreSQL + pgvector，而不是 Milvus？
- RAG 为什么会幻觉，如何降低？
- ReAct 循环怎么避免无限调用工具？
- MCP 和普通 HTTP 工具调用有什么区别？
- Spring AI 的 ChatClient、Tool Calling、VectorStore 在项目中怎么使用？
- 本地 Ollama 模型和云端 DeepSeek 如何统一接入？

## 4. 建议量化指标

等项目进入评测阶段后，建议补充真实数据：

- 累计导入 PDF/PPT 文档数量。
- 文档切片数量。
- 固定评测问题数量。
- TopK 召回命中率。
- 回答引用准确率。
- 平均响应耗时。
- 云模型 token 成本下降比例。

示例：

> 构建 300+ 文档切片的面试知识库，设计 50 道固定评测题，对比不同切分策略后将有效召回率从 X% 提升至 Y%，并通过引用溯源降低无依据回答比例。

## 5. 项目命名建议

Gewu Agent 这个名字可以保留。“格物”有学习、求知、探究原理的意味，和个人学习智能体平台比较契合。

可选英文副标题：

- Gewu Agent: Personal AI Agent and RAG Learning Platform
- Gewu Agent: A Spring AI based Multi-Agent Knowledge Platform
- Gewu Agent: Build, Learn, Retrieve, Act

