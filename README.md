# Qing

「轻籁」全栈项目：Vue 3 + TypeScript + Vite 前端，Spring Boot + PostgreSQL 后端。当前目标是保持极简并确保整条链路真实可运行。

## 目录结构

```
qing/
├── README.md
├── AGENTS.md
└── app/
    ├── backend/    # Maven 工程，包名 com.gemform.qing，端口 8080
    └── frontend/   # Vue 3 + TS + Vite，pnpm 管理，开发端口 5173
```

## 环境要求

- JDK 25、Maven 3.6.3
- Node.js 25、pnpm 12
- PostgreSQL 18（本机 5432 端口）

## 数据库

后端只依赖 PostgreSQL，连接参数见 `app/backend/src/main/resources/application.yml`：

- 库名：`qing`
- 用户：`postgres`
- 密码：从环境变量 `POSTGRES_PASSWORD` 读取，yml 中不写明文

首次使用需手动建库（Hibernate 只建表，不建库）：

```powershell
$env:PGPASSWORD=$env:POSTGRES_PASSWORD
psql -h localhost -p 5432 -U postgres -c "CREATE DATABASE qing;"
```

## 启动后端

`POSTGRES_PASSWORD` 必须是启动进程可见的环境变量（本机已设置为系统级变量）。先在 `app/backend` 构建，再启动：

```powershell
cd app/backend
mvn clean package -DskipTests
java -jar target/qing-0.0.1-SNAPSHOT.jar
```

或开发时直接运行：

```powershell
cd app/backend
mvn spring-boot:run
```

接口：

```powershell
curl http://localhost:8080/api/hello
```

返回示例：

```json
{"message":"Hello from Qing","database":"PostgreSQL 18.6","timestamp":"2026-11-18T20:00:00+08:00"}
```

其中 `database` 字段来自一次真实的数据库查询，可用于确认 PostgreSQL 已连通。

## 启动前端

```powershell
cd app/frontend
pnpm install
pnpm dev
```

访问 http://localhost:5173 。页面加载时会请求 `/api/hello`，由 Vite 开发代理（`vite.config.ts` 中的 `server.proxy`）转发到 `http://localhost:8080`，展示后端返回的 `message`、`database` 和 `timestamp`。

构建检查：

```powershell
pnpm build
```

## 一键启动（start.ps1）

根目录的 `start.ps1` 会同时拉起后端和前端，两个服务在独立窗口中后台运行，脚本打印地址后即退出，不会阻塞当前终端。

已占用的端口会被跳过：8080 已监听时不重复启动后端，5173 已监听时不重复启动前端。后端优先使用已构建的 jar，缺失时才执行 `mvn clean package -DskipTests`。

本机 CurrentUser 执行策略为 RemoteSigned，以下两种写法都可用：

```powershell
# 写法一：直接执行（本机本地脚本不受 RemoteSigned 拦截）
cd d:\workspace\vscode\qing
powershell -File .\start.ps1

# 写法二：显式绕过执行策略
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

本机 `.ps1` 的默认双击关联是记事本，直接双击只会打开文件而不会执行。请在资源管理器中右键脚本选择“使用 PowerShell 运行”，或使用上面的命令。

执行完成后会打印：

```
页面地址: http://localhost:5173
接口地址: http://localhost:8080/api/hello
```

## 停止服务

按端口反查监听进程，再结束对应 PID。后端监听 8080（java）、前端监听 5173（vite 启动的 node）。

分别停止：

```powershell
# 停后端 8080
Get-NetTCPConnection -LocalPort 8080 -State Listen |
  Select-Object -ExpandProperty OwningProcess |
  ForEach-Object { Stop-Process -Id $_ -Force }

# 停前端 5173
Get-NetTCPConnection -LocalPort 5173 -State Listen |
  Select-Object -ExpandProperty OwningProcess |
  ForEach-Object { Stop-Process -Id $_ -Force }
```

一次全停：

```powershell
Get-NetTCPConnection -LocalPort 8080, 5173 -State Listen |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object { Stop-Process -Id $_ -Force }
```

注意：

- 不要只结束 pnpm 的外层进程：pnpm 只是启动器，真正监听 5173 的是它拉起的 node（vite）子进程，只杀外层会让该 node 进程残留并继续占用端口。按端口找 PID 才能停干净。
- 如果服务是在前台终端里用 `pnpm dev` 或 `java -jar` 直接跑着的，在该终端按 `Ctrl+C` 即可，无需再查 PID。
- 停止前可先确认占用者：`Get-Process -Id <PID>` 查看进程名是否是 java / node。

## 当前验证结果

- 后端 `GET /api/hello` 返回 200，JSON 中包含实时查询到的 PostgreSQL 版本。
- 前端页面经 Vite 代理请求同一接口，成功渲染返回内容。
