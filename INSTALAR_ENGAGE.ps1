param(
    # Pasta onde o projeto será instalado. Por padrão, usa a pasta Documentos do usuário.
    [string]$Destination = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'engage-partner-intelligence'),
    # Use -CheckOnly para clonar/atualizar e validar os pré-requisitos sem iniciar o sistema.
    [switch]$CheckOnly
)

# ENGAGE PARTNER INTELLIGENCE - INSTALAÇÃO EM UM NOVO COMPUTADOR
#
# Este script:
# 1. Confere se o Git está instalado.
# 2. Clona o projeto do GitHub quando a pasta ainda não existe.
# 3. Executa "git pull" quando o projeto já foi clonado.
# 4. Chama o INICIAR_ENGAGE.ps1, que valida Python, dependências e banco.
#
# Execução:
# powershell -ExecutionPolicy Bypass -File .\INSTALAR_ENGAGE.ps1

$ErrorActionPreference = 'Stop'
$repository = 'https://github.com/thealebr/engage-partner-intelligence.git'
$git = Get-Command git -ErrorAction SilentlyContinue

if (-not $git) {
    throw 'Git não encontrado. Instale o Git for Windows em https://git-scm.com/download/win e execute este script novamente.'
}

$destinationFullPath = [System.IO.Path]::GetFullPath($Destination)
$gitFolder = Join-Path $destinationFullPath '.git'

if (Test-Path $gitFolder) {
    Write-Host "Projeto encontrado em $destinationFullPath" -ForegroundColor Green
    Write-Host 'Buscando a versão mais recente no GitHub...' -ForegroundColor Cyan
    & $git.Source -C $destinationFullPath pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        throw 'Não foi possível atualizar o projeto. Verifique se há alterações locais pendentes ou problemas de acesso ao GitHub.'
    }
} elseif (Test-Path $destinationFullPath) {
    $existingItems = @(Get-ChildItem -LiteralPath $destinationFullPath -Force -ErrorAction SilentlyContinue)
    if ($existingItems.Count -gt 0) {
        throw "A pasta de destino já existe e não está vazia: $destinationFullPath. Escolha outra pasta usando -Destination."
    }
    Write-Host 'Clonando o Engage do GitHub...' -ForegroundColor Cyan
    & $git.Source clone --branch main --single-branch $repository $destinationFullPath
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível clonar o projeto do GitHub.' }
} else {
    $parent = Split-Path -Parent $destinationFullPath
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Write-Host 'Clonando o Engage do GitHub...' -ForegroundColor Cyan
    & $git.Source clone --branch main --single-branch $repository $destinationFullPath
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível clonar o projeto do GitHub.' }
}

$launcher = Join-Path $destinationFullPath 'INICIAR_ENGAGE.ps1'
if (-not (Test-Path $launcher)) { throw "Arquivo de inicialização não encontrado: $launcher" }

Write-Host 'Projeto pronto. Validando e iniciando o Engage...' -ForegroundColor Cyan
if ($CheckOnly) {
    & powershell.exe -ExecutionPolicy Bypass -File $launcher -CheckOnly
} else {
    & powershell.exe -ExecutionPolicy Bypass -File $launcher
}

if ($LASTEXITCODE -ne 0) { throw 'A inicialização do Engage não foi concluída.' }
