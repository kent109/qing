# AGENTS.md

## 项目约定

- 「轻籁」项目，前后端目录严格分开：后端 `app/backend`，前端 `app/frontend`。
- 后端：Spring Boot 4.1.2 + Java 25，Maven 3.6.3，包名 `com.gemform.qing`，artifactId `qing`，端口 8080。架构为`spring-boot-starter-webmvc` + `spring-boot-starter-data-jpa` + PostgreSQL 驱动。
- 前端：Vue 3.5 + TypeScript + Vite 7，pnpm 管理，不引入 UI 组件库，样式手写。
- 数据库只配 PostgreSQL（本机 5432），库名 `qing`，密码只从 `POSTGRES_PASSWORD` 环境变量读取，不写进仓库。不引入其他中间件。

## 启动

```powershell
# 后端（app/backend）
mvn clean package -DskipTests
java -jar target/qing-0.0.1-SNAPSHOT.jar

# 前端（app/frontend）
pnpm install
pnpm dev
```

- 前端 http://localhost:5173，`/api` 由 Vite 代理到 http://localhost:8080。
- 后端接口：`GET /api/hello`，返回 `message` / `database` / `timestamp`。

## 注意事项

- Hibernate 只建表不建库，首次需手动 `CREATE DATABASE qing`。库不存在时 Hikari 启动即失败。
- 启动后端前确认 `POSTGRES_PASSWORD` 已注入当前进程；缺失时占位符不会被解析，会直接以认证失败告终。
- pnpm 12 默认拦截依赖构建脚本，esbuild 需要放行。放行记录在 `app/frontend/pnpm-workspace.yaml` 的 `allowBuilds`，不要删。
- 常驻服务验证时放后台启动，用带短超时的 HTTP 请求确认，不要在前台阻塞等待。

## .harness 目录

Harness 工程化配置与产物目录：

- `agents/`：各角色定义，含 planner（需求规划）、coder（编码实现）、reviewer（代码检视）、verifier（测试验证），并标明各自可读写的范围。
- `rules/`：常驻注入的安全红线，只放“不能做”的操作。
- `hooks/`：任务生命周期钩子，`pre_tool.py` 在工具调用前做危险模式检查，`post_task.py` 在任务完成后自动构建、测试、归档并更新状态。
- `scripts/`：可执行脚本，含编译、测试、需求/修复文档结构校验，以及带超时与资源限制的沙箱入口。
- `skills/`：技能说明，如 `bug-analysis`（问题定位与解决）、`requirement-writing`（需求文档编写）。
- `specs/`：编码、测试、部署三类规范。
- `sessions/current_state.md`：轻量状态指针（已完成 / 进行中 / 待完成 / 阻塞点），由 hook 覆盖写入而非追加。
- `deliverables/`：放置 Harness 交付物；`features/`、`bugfixes/` 分别存放功能需求与缺陷修复相关的文档及测试报告。
- `_archive/`：Harness 交付物的归档目录，自动将 `.harness/deliverables/` 中对应的需求文档、修复文档、测试报告移入，用来按需回顾已完成的工作。
