param(
    # Pasta onde o projeto sera instalado. Por padrao, usa Documentos do usuario.
    [string]$Destination = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'engage-partner-intelligence'),
    # Clona/atualiza e valida os requisitos, mas nao inicia o sistema.
    [switch]$CheckOnly
)

# ENGAGE PARTNER INTELLIGENCE - INSTALACAO EM UM NOVO COMPUTADOR
# Execucao recomendada: .\INSTALAR_ENGAGE.cmd

$ErrorActionPreference = 'Stop'
$repository = 'https://github.com/thealebr/engage-partner-intelligence.git'

function Find-Git {
    $command = Get-Command git -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidates = @()
    if ($env:LOCALAPPDATA) { $candidates += Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe' }
    if ($env:ProgramFiles) { $candidates += Join-Path $env:ProgramFiles 'Git\cmd\git.exe' }
    if (${env:ProgramFiles(x86)}) { $candidates += Join-Path ${env:ProgramFiles(x86)} 'Git\cmd\git.exe' }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    return $null
}

function Install-Git {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'Git e Windows Package Manager (winget) nao foram encontrados. Instale o App Installer pela Microsoft Store e execute novamente.'
    }
    Write-Host 'Git nao encontrado. Instalando Git for Windows...' -ForegroundColor Yellow
    & $winget.Source install --id Git.Git --exact --source winget --scope user --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw 'A instalacao automatica do Git nao foi concluida. Verifique as permissoes do Windows e tente novamente.'
    }
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

$git = Find-Git
if (-not $git) {
    Install-Git
    $git = Find-Git
}
if (-not $git) { throw 'O Git foi instalado, mas o executavel nao foi localizado. Feche esta janela e execute INSTALAR_ENGAGE.cmd novamente.' }
Write-Host 'Git disponivel.' -ForegroundColor Green

$destinationFullPath = [System.IO.Path]::GetFullPath($Destination)
$gitFolder = Join-Path $destinationFullPath '.git'
if (Test-Path $gitFolder) {
    Write-Host "Projeto encontrado em $destinationFullPath" -ForegroundColor Green
    Write-Host 'Buscando a versao mais recente no GitHub...' -ForegroundColor Cyan
    & $git -C $destinationFullPath pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel atualizar o projeto. Verifique alteracoes locais pendentes ou o acesso ao GitHub.' }
} elseif (Test-Path $destinationFullPath) {
    $existingItems = @(Get-ChildItem -LiteralPath $destinationFullPath -Force -ErrorAction SilentlyContinue)
    if ($existingItems.Count -gt 0) { throw "A pasta de destino ja existe e nao esta vazia: $destinationFullPath. Escolha outra pasta usando -Destination." }
    Write-Host 'Clonando o Engage do GitHub...' -ForegroundColor Cyan
    & $git clone --branch main --single-branch $repository $destinationFullPath
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel clonar o projeto do GitHub.' }
} else {
    $parent = Split-Path -Parent $destinationFullPath
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Write-Host 'Clonando o Engage do GitHub...' -ForegroundColor Cyan
    & $git clone --branch main --single-branch $repository $destinationFullPath
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel clonar o projeto do GitHub.' }
}

$launcher = Join-Path $destinationFullPath 'INICIAR_ENGAGE.ps1'
if (-not (Test-Path $launcher)) { throw "Arquivo de inicializacao nao encontrado: $launcher" }
Write-Host 'Projeto pronto. Validando e iniciando o Engage...' -ForegroundColor Cyan
if ($CheckOnly) { & powershell.exe -ExecutionPolicy Bypass -File $launcher -CheckOnly } else { & powershell.exe -ExecutionPolicy Bypass -File $launcher }
if ($LASTEXITCODE -ne 0) { throw 'A inicializacao do Engage nao foi concluida.' }
