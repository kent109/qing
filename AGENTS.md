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
