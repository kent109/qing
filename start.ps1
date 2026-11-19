#Requires -Version 5.1
<#
一键启动 Qing 前后端（Windows PowerShell）

用法：
  powershell -ExecutionPolicy Bypass -File .\start.ps1

行为：
  - 8080 已占用时跳过后端，5173 已占用时跳过前端；
  - 后端优先使用 app/backend/target 下已构建的 jar，没有则先 mvn clean package -DskipTests；
  - 前端用 pnpm dev；
  - 两个服务都放到独立进程窗口，本脚本不驻留、不阻塞。
#>

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $Root 'app\backend'
$FrontendDir = Join-Path $Root 'app\frontend'
$BackendPort = 8080
$FrontendPort = 5173

function Test-PortListening {
    param([int]$Port)
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-PortListening {
    param([int]$Port, [int]$TimeoutSeconds = 30)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-PortListening -Port $Port) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

function Get-BackendJar {
    $targetDir = Join-Path $BackendDir 'target'
    return Get-ChildItem -Path $targetDir -Filter 'qing-*.jar' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.original' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

# ---------- 后端 ----------
$backendStarted = $false
$backendSkipped = $false

if (Test-PortListening -Port $BackendPort) {
    Write-Host "[跳过] 后端：端口 $BackendPort 已被占用" -ForegroundColor Yellow
    $backendSkipped = $true
}
else {
    if (-not $env:POSTGRES_PASSWORD) {
        Write-Warning '未设置 POSTGRES_PASSWORD，后端可能无法连接 PostgreSQL。'
    }

    $jar = Get-BackendJar
    if (-not $jar) {
        Write-Host '[构建] 未找到已构建的 jar，执行 mvn clean package -DskipTests ...'
        Push-Location $BackendDir
        try {
            & mvn -B clean package -DskipTests
            if ($LASTEXITCODE -ne 0) { throw "Maven 构建失败，退出码 $LASTEXITCODE" }
        }
        finally {
            Pop-Location
        }
        $jar = Get-BackendJar
        if (-not $jar) { throw '构建完成后仍未找到 target\qing-*.jar' }
    }

    Write-Host "[启动] 后端：$($jar.Name)" -ForegroundColor Green
    Start-Process -FilePath 'java' -ArgumentList @('-jar', $jar.FullName) -WorkingDirectory $BackendDir | Out-Null
    $backendStarted = $true
}

# ---------- 前端 ----------
$frontendStarted = $false
$frontendSkipped = $false

if (Test-PortListening -Port $FrontendPort) {
    Write-Host "[跳过] 前端：端口 $FrontendPort 已被占用" -ForegroundColor Yellow
    $frontendSkipped = $true
}
else {
    $pnpm = Get-Command pnpm.cmd -ErrorAction SilentlyContinue
    if (-not $pnpm) { throw '未找到 pnpm.cmd，请先安装 pnpm 并加入 PATH。' }

    Write-Host '[启动] 前端：pnpm dev' -ForegroundColor Green
    Start-Process -FilePath $pnpm.Source -ArgumentList @('dev') -WorkingDirectory $FrontendDir | Out-Null
    $frontendStarted = $true
}

# 有限等待端口就绪，只用于打印状态，不驻留服务进程
if ($backendStarted) {
    if (Wait-PortListening -Port $BackendPort) {
        Write-Host "[就绪] 后端已监听 $BackendPort" -ForegroundColor Green
    }
    else {
        Write-Warning "后端 30 秒内未监听 $BackendPort，请查看新窗口中 java 进程的输出。"
    }
}
if ($frontendStarted) {
    if (Wait-PortListening -Port $FrontendPort) {
        Write-Host "[就绪] 前端已监听 $FrontendPort" -ForegroundColor Green
    }
    else {
        Write-Warning "前端 30 秒内未监听 $FrontendPort，请查看新窗口中 pnpm 的输出。"
    }
}

Write-Host ''
Write-Host "页面地址: http://localhost:$FrontendPort"
Write-Host "接口地址: http://localhost:$BackendPort/api/hello"
if ($backendSkipped -or $frontendSkipped) {
    Write-Host '（已占用端口对应服务被跳过，未重复启动）' -ForegroundColor DarkGray
}
