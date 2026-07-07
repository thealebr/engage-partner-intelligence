param(
    # Use -CheckOnly para validar os pré-requisitos sem iniciar a aplicação.
    [switch]$CheckOnly,
    # Opcional: informe o caminho do python.exe quando ele não estiver no PATH.
    [string]$PythonPath = $env:ENGAGE_PYTHON
)

# ENGAGE PARTNER INTELLIGENCE
#
# Pré-requisitos:
# - Windows 10 ou 11.
# - Python 3.10, 3.11 ou 3.12 disponível no PATH.
# - Acesso à internet somente na primeira execução, caso o openpyxl precise ser instalado.
# - Portas locais 8765 e 8767 disponíveis.
#
# Como executar:
# powershell -ExecutionPolicy Bypass -File .\INICIAR_ENGAGE.ps1
#
# Depois da inicialização, acesse:
# http://127.0.0.1:8765/
#
# Não é necessário instalar Node.js, PowerPoint ou SQLite separadamente.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Python([string]$Preferred) {
    $candidates = @(
        $Preferred,
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python310\python.exe')
    )

    $pathPython = Get-Command python -ErrorAction SilentlyContinue
    if ($pathPython) { $candidates += $pathPython.Source }

    $launcher = Get-Command py -ErrorAction SilentlyContinue
    if ($launcher) {
        foreach ($requestedVersion in @('3.12','3.11','3.10')) {
            try {
                $resolved = & $launcher.Source "-$requestedVersion" -c "import sys; print(sys.executable)" 2>$null
                if ($LASTEXITCODE -eq 0 -and $resolved) { $candidates += $resolved.Trim() }
            } catch { }
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (-not $candidate -or -not (Test-Path $candidate)) { continue }
        try {
            & $candidate -c "import sys; print(sys.version_info.major, sys.version_info.minor)" 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { return $candidate }
        } catch { }
    }
    return $null
}

function Test-PortOpen([int]$Port) {
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-Endpoint([string]$Url, [int]$Seconds = 12) {
    for ($attempt = 0; $attempt -lt $Seconds; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) { return $true }
        } catch { }
        Start-Sleep -Seconds 1
    }
    return $false
}

Write-Host 'Verificando pré-requisitos do Engage...' -ForegroundColor Cyan

$python = Find-Python $PythonPath
if (-not $python) {
    throw 'Python não encontrado. Instale Python 3.11 ou 3.12 em https://www.python.org/downloads/ e marque a opção Add Python to PATH.'
}

$version = & $python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
$versionParts = $version.Split('.')
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
if ($major -ne 3 -or $minor -lt 10 -or $minor -gt 12) {
    throw "Python $version não é compatível. Use Python 3.10, 3.11 ou 3.12."
}
Write-Host "Python $version encontrado." -ForegroundColor Green

& $python -c "import openpyxl" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Instalando a dependência openpyxl...' -ForegroundColor Yellow
    & $python -m pip install --user 'openpyxl>=3.1,<4'
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível instalar o openpyxl.' }
}
Write-Host 'Dependência openpyxl disponível.' -ForegroundColor Green

$database = Join-Path $root 'backend\engage.db'
if (-not (Test-Path $database)) { throw "Banco não encontrado: $database" }
Write-Host 'Banco SQLite encontrado.' -ForegroundColor Green

if ($CheckOnly) {
    Write-Host 'Todos os pré-requisitos foram atendidos.' -ForegroundColor Green
    exit 0
}

if (-not (Test-PortOpen 8767)) {
    Start-Process -FilePath $python -ArgumentList '.\backend\server.py' -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput "$root\backend\server-8767.log" -RedirectStandardError "$root\backend\server-8767.err"
}
if (-not (Wait-Endpoint 'http://127.0.0.1:8767/api/periods')) {
    throw 'A API não iniciou na porta 8767. Consulte backend\server-8767.err.'
}

if (-not (Test-PortOpen 8765)) {
    Start-Process -FilePath $python -ArgumentList '-m','http.server','8765','--directory','FTNT-Engage' -WorkingDirectory $root -WindowStyle Hidden
}
if (-not (Wait-Endpoint 'http://127.0.0.1:8765/')) {
    throw 'A interface não iniciou na porta 8765.'
}

Write-Host 'Engage disponível em http://127.0.0.1:8765/' -ForegroundColor Green
Start-Process 'http://127.0.0.1:8765/'
