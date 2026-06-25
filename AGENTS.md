# AGENTS.md

本文件是 Gewu Agent 仓库的 Codex 开发约束。后续在本仓库内进行设计、编码、文档更新和审查时，应优先遵循这里的规则。

## 项目定位

Gewu Agent 是一个个人智能体平台，核心目标是学习和实践 Spring AI、RAG、Tool Calling、MCP、文档解析、向量检索和自研 ReAct Agent。

首期智能体：

- 面试助手：基于面试 PDF 知识库，提供结构化面试问答、模拟追问和复盘。
- 考研学习助手：基于 408 PDF/PPT 课件，提供知识点解释、章节摘要和复习建议。
- LeManus：自研 ReAct 智能体运行时，强调可解释、可调试、可控的执行循环。

## 文档约束

- Spring AI 只引用 2.0 GA 文档：https://docs.spring.io/spring-ai/reference/index.html
- 不引用 Spring AI 2.0-SNAPSHOT 文档。
- 涉及 Spring AI API、依赖、MCP、Tool Calling、RAG、VectorStore、ChatClient 时，必须先使用 Context7 查询当前稳定文档。
- DeepSeek 模型命名使用官方新口径：`deepseek-v4-flash` 和 `deepseek-v4-pro`。
- 不再使用 `deepseek-chat`、`deepseek-reasoner` 作为项目默认模型名。

## 技术栈约束

- Backend: Spring Boot 4.x, Spring AI 2.0 GA, JDK 21
- Frontend: Vue, TypeScript, Vite
- Vector Store 首期优先 PostgreSQL + pgvector
- PDF 首期优先 Spring AI PDF Document Reader
- PPT/PPTX 首期使用 Apache Tika 抽取文本；需要 slide、shape、notes 细粒度解析时再引入 Apache POI
- 阶段 0 只接 DeepSeek v4 flash/pro；先不要接本地 Ollama

## 前端设计约束

- 每次设计或实现前端页面、组件、布局、配色、图标、动效和文案时，必须先遵循 `docs/05-frontend-design-guidelines.md`。
- Gewu Agent 的 UI 不允许做成千篇一律的 SaaS 模板，不使用 Hero + 三卡片首页，不使用 Tailwind 默认色板，不使用紫色/靛蓝色/蓝紫渐变作为主视觉。
- 前端页面应优先服务学习和智能体工作台场景：信息密度清晰、状态可扫描、引用和工具轨迹可追踪，同时保留非模板化的视觉个性。
- 图标默认使用 Iconify；不使用 emoji 作为功能图标。
- 组件库可以作为底层能力，但所有按钮、卡片、表格、侧栏、弹窗和表单都必须进行项目化定制，不直接暴露 Shadcn、Material UI 或 Element Plus 默认观感。
- 文案必须口语化、具体、有场景；禁止 Lorem Ipsum、空泛营销话术和长句堆叠。

## 开发原则

- 先完成端到端闭环，再优化效果。
- 框架开发遵循“官方稳定文档、主流高层 API、框架自动配置优先”：先按官方推荐路径实现，再考虑自定义适配。
- Spring AI 统一优先使用 Starter 自动配置、`ChatClient`、`ChatModel`、Advisor、Tool Calling、VectorStore 等高层抽象；不在业务层手工创建 `DeepSeekApi`、`DeepSeekChatModel` 或重复定义框架已有的配置属性。
- Spring AI 配置必须使用 2.0 GA 官方属性层级，例如 `spring.ai.model.chat=deepseek` 和 `spring.ai.deepseek.chat.options.*`；不得通过关闭自动配置后手工补 Bean 来掩盖配置问题。
- 遇到框架调用异常时，先检查依赖版本、配置属性、自动配置条件、Bean 注入和官方示例，再判断框架缺陷。
- 只有在官方高层 API 无法满足需求且已有可复现证据时，才允许封装低层供应商 API；必须隔离在适配层、补充回归测试并记录恢复高层 API 的条件。
- RAG 相关功能必须保留来源引用和检索调试能力。
- Agent 工具调用必须有白名单、超时、最大步数和执行日志。
- 模型、向量库、文档解析器都应通过接口隔离，避免写死实现。
- 简历亮点优先来自真实工程能力：RAG 评测、引用溯源、工具轨迹、模型路由、MCP 接入、自研 ReAct。

## 启动脚本约束

- 日常后端开发使用 `start-dev.ps1` 前台启动，保持窗口常驻，停止时由用户按 `Ctrl+C`。
- `stop-dev.ps1` 只用于清理残留后端进程或端口占用。
- Git Bash 脚本仅保留 `start.sh`、`stop.sh`、`restart.sh`。
- 不新增或推荐 cmd 版本脚本；不新增 `restart-dev.ps1` 作为常规开发入口。

## 文档维护

- 产品和技术决策同步更新 `README.md` 和 `docs/`。
- 需求变化优先更新 `docs/01-product-requirements.md`。
- 架构或技术选型变化优先更新 `docs/02-technical-architecture.md`。
- 阶段计划变化优先更新 `docs/03-roadmap.md`。
- 简历表达和项目亮点变化优先更新 `docs/04-resume-value.md`。
- 前端视觉、交互、文案、图标和布局规范变化优先更新 `docs/05-frontend-design-guidelines.md`。
