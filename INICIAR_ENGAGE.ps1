param(
    # Valida os requisitos sem iniciar a aplicacao.
    [switch]$CheckOnly,
    # Caminho opcional do python.exe quando houver uma instalacao personalizada.
    [string]$PythonPath = $env:ENGAGE_PYTHON
)

# ENGAGE PARTNER INTELLIGENCE
#
# Este script instala automaticamente Python 3.12 e openpyxl quando necessario.
# Nao e necessario instalar Node.js, PowerPoint ou SQLite separadamente.
# Portas locais utilizadas: 8765 e 8767.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Python([string]$Preferred) {
    $candidates = @()
    if ($Preferred) { $candidates += $Preferred }
    if ($env:LOCALAPPDATA) {
        $candidates += Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
        $candidates += Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe'
        $candidates += Join-Path $env:LOCALAPPDATA 'Programs\Python\Python310\python.exe'
    }
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
            $candidateVersion = & $candidate -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
            if ($LASTEXITCODE -eq 0 -and $candidateVersion -match '^3\.(10|11|12)$') { return $candidate }
        } catch { }
    }
    return $null
}

function Install-Python {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'Python e Windows Package Manager (winget) nao foram encontrados. Instale o App Installer pela Microsoft Store e execute novamente.'
    }
    Write-Host 'Python nao encontrado. Instalando Python 3.12...' -ForegroundColor Yellow
    & $winget.Source install --id Python.Python.3.12 --exact --source winget --scope user --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw 'A instalacao automatica do Python nao foi concluida. Verifique as permissoes do Windows.' }
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
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

Write-Host 'Verificando requisitos do Engage...' -ForegroundColor Cyan
$python = Find-Python $PythonPath
if (-not $python) {
    Install-Python
    $python = Find-Python $null
}
if (-not $python) { throw 'O Python foi instalado, mas o executavel nao foi localizado. Feche esta janela e execute INSTALAR_ENGAGE.cmd novamente.' }

$version = & $python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
$versionParts = $version.Split('.')
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
if ($major -ne 3 -or $minor -lt 10 -or $minor -gt 12) {
    throw "Python $version nao e compativel. Use Python 3.10, 3.11 ou 3.12."
}
Write-Host "Python $version disponivel." -ForegroundColor Green

& $python -c "import openpyxl" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Instalando a dependencia openpyxl...' -ForegroundColor Yellow
    & $python -m pip install --user 'openpyxl>=3.1,<4'
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel instalar o openpyxl.' }
}
Write-Host 'Dependencias Python disponiveis.' -ForegroundColor Green

$database = Join-Path $root 'backend\engage.db'
if (-not (Test-Path $database)) { throw "Banco nao encontrado: $database" }
Write-Host 'Banco SQLite encontrado.' -ForegroundColor Green

if ($CheckOnly) {
    Write-Host 'Todos os requisitos foram atendidos.' -ForegroundColor Green
    exit 0
}

if (-not (Test-PortOpen 8767)) {
    Start-Process -FilePath $python -ArgumentList '.\backend\server.py' -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput "$root\backend\server-8767.log" -RedirectStandardError "$root\backend\server-8767.err"
}
if (-not (Wait-Endpoint 'http://127.0.0.1:8767/api/periods')) {
    throw 'A API nao iniciou na porta 8767. Consulte backend\server-8767.err.'
}
if (-not (Test-PortOpen 8765)) {
    Start-Process -FilePath $python -ArgumentList '-m','http.server','8765','--directory','FTNT-Engage' -WorkingDirectory $root -WindowStyle Hidden
}
if (-not (Wait-Endpoint 'http://127.0.0.1:8765/')) { throw 'A interface nao iniciou na porta 8765.' }

Write-Host 'Engage disponivel em http://127.0.0.1:8765/' -ForegroundColor Green
Start-Process 'http://127.0.0.1:8765/'
