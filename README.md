# Gewu Agent

Gewu Agent 是一个面向个人学习、知识库问答和智能体框架实践的自研智能体平台。

项目目标不是简单套壳调用大模型，而是通过 Spring AI、RAG、Tool Calling、MCP 和自研 ReAct 执行循环，搭建一套可扩展、可解释、可沉淀的个人 AI 应用平台。

## 核心智能体

| 智能体 | 一句话定位 | 首期知识来源 | 核心能力 |
| --- | --- | --- | --- |
| 面试助手 | 面向 Java/后端/算法/项目面试的个人问答教练 | 面试鸭 PDF 面试题 | 知识库问答、追问、答案结构化、薄弱点复盘 |
| 考研学习助手 | 面向 408 复习的课程资料学习助手 | 408 PDF 课件，后续支持 PPT/PPTX | 概念解释、章节总结、题目讲解、知识点关联 |
| LeManus | 自研 ReAct 智能体，用于理解和实践 Agent 原理 | 工具、MCP 服务、用户任务上下文 | 计划、执行、观察、反思、工具调用 |
| 扩展智能体 | 面向未来新增场景的配置化智能体 | 用户自定义知识库和工具集 | 角色配置、知识库绑定、工具授权 |

## 技术方向

- Backend: Spring Boot 4.x, Spring AI 2.0 GA, JDK 21
- Frontend: Vue, TypeScript, Vite
- AI: DeepSeek v4 flash/pro 云模型
- RAG: 本地文档知识库、云知识库、向量数据库
- Tools: Spring AI Tool Calling, MCP Client/Server
- Documents: PDF 首期支持，PPT/PPTX 作为增强能力纳入规划

## 开发规范

Spring AI 开发统一以 [Spring AI 2.0.0 GA Reference](https://docs.spring.io/spring-ai/reference/index.html) 为准：

- 优先使用 Starter 自动配置和 `ChatClient`、`ChatModel`、Advisor、Tool Calling、VectorStore 等高层 API。
- 同步聊天使用 `chatClient.prompt().call().content()`，流式聊天使用 `chatClient.prompt().stream().content()`。
- 优先排查依赖、官方配置属性、自动配置条件和 Bean 注入，不通过手工创建供应商客户端掩盖配置错误。
- 只有高层 API 明确无法满足需求时，才在独立适配层使用低层 API，并补充复现证据与回归测试。

详细约束见 [技术架构文档](docs/02-technical-architecture.md)。

## 本地启动

后端在项目根目录，前端在 `frontend/`。

后端需要配置 DeepSeek API Key。日常使用 PowerShell 启动时，先复制开发配置模板：

```powershell
Copy-Item .\src\main\resources\application-example.yml .\src\main\resources\application-dev.yml
```

然后编辑已被 Git 忽略的 `application-dev.yml`：

```yaml
spring:
  ai:
    model:
      chat: deepseek
    deepseek:
      api-key: 你的_key
      chat:
        options:
          model: deepseek-v4-flash
          temperature: 0.7
```

Git Bash 脚本保留作为兼容方案：

```bash
printf 'DEEPSEEK_API_KEY=你的_key\n' > .env
```

```bash
./start.sh --build
```

停止：

```bash
./stop.sh
```

重启：

```bash
./restart.sh
```

常用参数：

```bash
./start.sh --port 8081
./start.sh --build --port 8081
./restart.sh --build
```

脚本会自动加载 `.env`、查找 JDK 21、在后端资源或源码变化后自动重新构建，并把完整日志写入 `.run/logs/`。命令行会直接打印 PID、URL、DeepSeek Key 配置状态和 Spring Boot 启动摘要。

日常开发推荐使用 PowerShell 前台模式，直接运行源码和配置：

```powershell
.\start-dev.ps1
```

`start-dev.ps1` 使用 `mvn spring-boot:run`，会在当前窗口输出 Spring Boot 日志；需要停止时直接按 `Ctrl+C`。如果曾经有后台残留进程或端口占用，再使用：

```powershell
.\stop-dev.ps1
```

当前推荐保留的启动脚本只有：`start-dev.ps1`、`stop-dev.ps1`、`start.sh`、`stop.sh`、`restart.sh`。

前端启动：

```bash
cd frontend
npm install
npm run dev
```

## 文档入口

- [产品需求文档](docs/01-product-requirements.md)
- [技术架构文档](docs/02-technical-architecture.md)
- [路线图与里程碑](docs/03-roadmap.md)
- [项目亮点与简历表达](docs/04-resume-value.md)
- [前端设计规范](docs/05-frontend-design-guidelines.md)

## 关键判断

直接把 PDF 投喂给在线大模型可以解决一次性问答，但难以形成稳定、可复用、可评估的学习系统。

Gewu Agent 的价值在于：

- 知识可沉淀：文档、切片、向量、问答历史、错题和薄弱点都能长期保存。
- 检索可控制：可以调整切分策略、召回数量、重排策略、引用来源和权限边界。
- 智能体可扩展：不同智能体可以绑定不同知识库、提示词、工具和模型。
- 工程能力可展示：项目覆盖 Spring AI、RAG、Tool Calling、MCP、文档解析、向量数据库和前后端工程化。
